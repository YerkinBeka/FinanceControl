package main

import (
	"context"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type RegisterReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type CategoryCreateReq struct {
	Name string `json:"name"`
}

type CategoryUpdateReq struct {
	Name string `json:"name"`
}

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://postgres:Yerkinbek_1979%21@localhost:5432/inf229_project_app?sslmode=disable"
	}

	db, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	r := gin.Default()
	r.Use(cors.New(cors.Config{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders: []string{"Origin", "Content-Type", "Authorization"},
		MaxAge:       12 * time.Hour,
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"ok": true})
	})

	// AUTH

	r.POST("/auth/register", func(c *gin.Context) {
		var req RegisterReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		email := strings.TrimSpace(strings.ToLower(req.Email))
		if email == "" || !strings.Contains(email, "@") {
			c.JSON(400, gin.H{"error": "invalid email"})
			return
		}
		if len(req.Password) < 6 {
			c.JSON(400, gin.H{"error": "password must be at least 6 chars"})
			return
		}

		hashBytes, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(500, gin.H{"error": "hash error"})
			return
		}

		_, err = db.Exec(context.Background(),
			`INSERT INTO users (email, password_hash) VALUES ($1, $2)`,
			email, string(hashBytes),
		)
		if err != nil {
			c.JSON(409, gin.H{"error": "email already exists"})
			return
		}

		c.JSON(201, gin.H{"message": "registered"})
	})

	r.POST("/auth/login", func(c *gin.Context) {
		var req LoginReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		email := strings.TrimSpace(strings.ToLower(req.Email))
		if email == "" || !strings.Contains(email, "@") {
			c.JSON(400, gin.H{"error": "invalid email"})
			return
		}

		var id int
		var hash string
		err := db.QueryRow(context.Background(),
			`SELECT id, password_hash FROM users WHERE email=$1`,
			email,
		).Scan(&id, &hash)

		if err != nil || bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)) != nil {
			c.JSON(401, gin.H{"error": "invalid credentials"})
			return
		}

		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "dev_secret"
		}

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"sub": id,
			"exp": time.Now().Add(24 * time.Hour).Unix(),
		})
		signed, err := token.SignedString([]byte(secret))
		if err != nil {
			c.JSON(500, gin.H{"error": "token error"})
			return
		}

		c.JSON(200, gin.H{"token": signed})
	})

	// PROTECTED

	api := r.Group("/")
	api.Use(authMiddleware())

	// PROFILE

	api.GET("/me", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		var email string
		err := db.QueryRow(context.Background(),
			`SELECT email FROM users WHERE id=$1`,
			uid,
		).Scan(&email)

		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}

		c.JSON(200, gin.H{"email": email})
	})

	api.PUT("/auth/password", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		var req struct {
			OldPassword string `json:"old_password"`
			NewPassword string `json:"new_password"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		if len(req.NewPassword) < 6 {
			c.JSON(400, gin.H{"error": "password must be at least 6 chars"})
			return
		}

		var hash string
		err := db.QueryRow(context.Background(),
			`SELECT password_hash FROM users WHERE id=$1`,
			uid,
		).Scan(&hash)

		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}

		if bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.OldPassword)) != nil {
			c.JSON(401, gin.H{"error": "wrong password"})
			return
		}

		newHash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(500, gin.H{"error": "hash error"})
			return
		}

		_, err = db.Exec(context.Background(),
			`UPDATE users SET password_hash=$1 WHERE id=$2`,
			string(newHash), uid,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}

		c.JSON(200, gin.H{"message": "password updated"})
	})

	// BUDGET

	api.GET("/budget", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		start, end := rangeDates("month")

		var spent float64
		_ = db.QueryRow(context.Background(),
			`SELECT COALESCE(SUM(amount),0)
			 FROM expenses
			 WHERE user_id=$1 AND spent_at >= $2 AND spent_at <= $3`,
			uid, start, end,
		).Scan(&spent)

		var budget float64
		err := db.QueryRow(context.Background(),
			`SELECT COALESCE(amount,0) FROM budgets WHERE user_id=$1`,
			uid,
		).Scan(&budget)

		if err != nil {
			budget = 0
		}

		remaining := budget - spent

		c.JSON(200, gin.H{
			"budget":    budget,
			"spent":     spent,
			"remaining": remaining,
		})
	})

	api.POST("/budget", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		var req struct {
			Amount float64 `json:"amount"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		if req.Amount < 0 {
			c.JSON(400, gin.H{"error": "amount must be >= 0"})
			return
		}

		_, err := db.Exec(context.Background(),
			`INSERT INTO budgets(user_id, amount, updated_at)
			 VALUES ($1,$2,NOW())
			 ON CONFLICT (user_id)
			 DO UPDATE SET amount=EXCLUDED.amount, updated_at=NOW()`,
			uid, req.Amount,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}

		c.JSON(200, gin.H{"message": "saved"})
	})

	// CATEGORIES

	api.GET("/categories", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		rows, err := db.Query(context.Background(),
			`SELECT id, name FROM categories WHERE user_id=$1 ORDER BY created_at ASC`,
			uid,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}
		defer rows.Close()

		var out []gin.H
		for rows.Next() {
			var id int
			var name string
			_ = rows.Scan(&id, &name)
			out = append(out, gin.H{"id": id, "name": name})
		}
		c.JSON(200, out)
	})

	api.POST("/categories", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		var req CategoryCreateReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		name := strings.TrimSpace(req.Name)
		if name == "" {
			c.JSON(400, gin.H{"error": "name is required"})
			return
		}

		var id int
		err := db.QueryRow(context.Background(),
			`INSERT INTO categories(user_id, name) VALUES ($1,$2) RETURNING id`,
			uid, name,
		).Scan(&id)

		if err != nil {
			c.JSON(409, gin.H{"error": "category exists"})
			return
		}

		c.JSON(201, gin.H{"id": id, "name": name})
	})

	api.PUT("/categories/:id", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		cid, _ := strconv.Atoi(c.Param("id"))

		var req CategoryUpdateReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		name := strings.TrimSpace(req.Name)
		if name == "" {
			c.JSON(400, gin.H{"error": "name is required"})
			return
		}

		tag, err := db.Exec(context.Background(),
			`UPDATE categories SET name=$1 WHERE id=$2 AND user_id=$3`,
			name, cid, uid,
		)
		if err != nil || tag.RowsAffected() == 0 {
			c.JSON(404, gin.H{"error": "not found"})
			return
		}

		c.JSON(200, gin.H{"message": "updated"})
	})

	api.DELETE("/categories/:id", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		cid, _ := strconv.Atoi(c.Param("id"))

		tag, err := db.Exec(context.Background(),
			`DELETE FROM categories WHERE id=$1 AND user_id=$2`,
			cid, uid,
		)
		if err != nil || tag.RowsAffected() == 0 {
			c.JSON(404, gin.H{"error": "not found"})
			return
		}

		c.JSON(200, gin.H{"message": "deleted"})
	})

	// SUMMARY

	api.GET("/summary", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		start, end := parseDateRange(c)

		var total float64
		_ = db.QueryRow(context.Background(),
			`SELECT COALESCE(SUM(amount),0)
			 FROM expenses
			 WHERE user_id=$1 AND spent_at >= $2 AND spent_at <= $3`,
			uid, start, end,
		).Scan(&total)

		rows, err := db.Query(context.Background(),
			`SELECT c.id, c.name, COALESCE(SUM(e.amount),0) AS sum
			 FROM categories c
			 LEFT JOIN expenses e
			   ON e.category_id=c.id AND e.user_id=c.user_id
			  AND e.spent_at >= $2 AND e.spent_at <= $3
			 WHERE c.user_id=$1
			 GROUP BY c.id, c.name
			 ORDER BY c.created_at ASC`,
			uid, start, end,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}
		defer rows.Close()

		var cats []gin.H
		for rows.Next() {
			var id int
			var name string
			var sum float64
			_ = rows.Scan(&id, &name, &sum)
			cats = append(cats, gin.H{"id": id, "name": name, "sum": sum})
		}

		c.JSON(200, gin.H{"total": total, "categories": cats})
	})

	// EXPENSES

	api.GET("/expenses", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		catID, _ := strconv.Atoi(c.Query("category_id"))
		start, end := parseDateRange(c)

		rows, err := db.Query(context.Background(),
			`SELECT id, note, amount, spent_at
			 FROM expenses
			 WHERE user_id=$1 AND category_id=$2
			   AND spent_at >= $3 AND spent_at <= $4
			 ORDER BY spent_at DESC`,
			uid, catID, start, end,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}
		defer rows.Close()

		var out []gin.H
		for rows.Next() {
			var id int
			var note string
			var amount float64
			var spentAt time.Time
			_ = rows.Scan(&id, &note, &amount, &spentAt)

			out = append(out, gin.H{
				"id":       id,
				"note":     note,
				"amount":   amount,
				"spent_at": spentAt.Format("2006-01-02"),
			})
		}

		c.JSON(200, out)
	})

	api.POST("/expenses", func(c *gin.Context) {
		uid := c.GetInt("user_id")

		var req struct {
			CategoryID int     `json:"category_id"`
			Note       string  `json:"note"`
			Amount     float64 `json:"amount"`
			SpentAt    string  `json:"spent_at"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		if req.CategoryID <= 0 || req.Amount <= 0 || strings.TrimSpace(req.Note) == "" {
			c.JSON(400, gin.H{"error": "missing fields"})
			return
		}

		date, err := time.Parse("2006-01-02", req.SpentAt)
		if err != nil {
			c.JSON(400, gin.H{"error": "invalid date"})
			return
		}

		_, err = db.Exec(context.Background(),
			`INSERT INTO expenses(user_id, category_id, note, amount, spent_at)
			 VALUES ($1,$2,$3,$4,$5)`,
			uid, req.CategoryID, req.Note, req.Amount, date,
		)
		if err != nil {
			c.JSON(500, gin.H{"error": "db error"})
			return
		}

		c.JSON(201, gin.H{"message": "created"})
	})

	api.PUT("/expenses/:id", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		eid, _ := strconv.Atoi(c.Param("id"))

		var req struct {
			CategoryID int     `json:"category_id"`
			Note       string  `json:"note"`
			Amount     float64 `json:"amount"`
			SpentAt    string  `json:"spent_at"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid json"})
			return
		}

		if req.CategoryID <= 0 || req.Amount <= 0 || strings.TrimSpace(req.Note) == "" {
			c.JSON(400, gin.H{"error": "missing fields"})
			return
		}

		date, err := time.Parse("2006-01-02", req.SpentAt)
		if err != nil {
			c.JSON(400, gin.H{"error": "invalid date"})
			return
		}

		tag, err := db.Exec(context.Background(),
			`UPDATE expenses
			 SET category_id=$1, note=$2, amount=$3, spent_at=$4
			 WHERE id=$5 AND user_id=$6`,
			req.CategoryID, req.Note, req.Amount, date, eid, uid,
		)
		if err != nil || tag.RowsAffected() == 0 {
			c.JSON(404, gin.H{"error": "not found"})
			return
		}

		c.JSON(200, gin.H{"message": "updated"})
	})

	api.DELETE("/expenses/:id", func(c *gin.Context) {
		uid := c.GetInt("user_id")
		eid, _ := strconv.Atoi(c.Param("id"))

		tag, err := db.Exec(context.Background(),
			`DELETE FROM expenses WHERE id=$1 AND user_id=$2`,
			eid, uid,
		)
		if err != nil || tag.RowsAffected() == 0 {
			c.JSON(404, gin.H{"error": "not found"})
			return
		}

		c.JSON(200, gin.H{"message": "deleted"})
	})

	r.Run(":8080")
}

func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		h := c.GetHeader("Authorization")
		if !strings.HasPrefix(h, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			c.Abort()
			return
		}

		tokenStr := strings.TrimPrefix(h, "Bearer ")

		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "dev_secret"
		}

		tok, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
			return []byte(secret), nil
		})
		if err != nil || !tok.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}

		claims := tok.Claims.(jwt.MapClaims)
		c.Set("user_id", int(claims["sub"].(float64)))
		c.Next()
	}
}

func rangeDates(key string) (time.Time, time.Time) {
	now := time.Now()
	y, m, d := now.Date()
	loc := now.Location()

	switch key {
	case "today":
		start := time.Date(y, m, d, 0, 0, 0, 0, loc)
		end := time.Date(y, m, d, 23, 59, 59, 0, loc)
		return start, end
	case "week":
		end := time.Date(y, m, d, 23, 59, 59, 0, loc)
		start := end.AddDate(0, 0, -6)
		start = time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, loc)
		return start, end
	default:
		start := time.Date(y, m, 1, 0, 0, 0, 0, loc)
		end := start.AddDate(0, 1, 0).Add(-time.Second)
		return start, end
	}
}

func parseDateRange(c *gin.Context) (time.Time, time.Time) {
	startStr := c.Query("start")
	endStr := c.Query("end")

	if startStr != "" && endStr != "" {
		start, err1 := time.Parse("2006-01-02", startStr)
		end, err2 := time.Parse("2006-01-02", endStr)
		if err1 == nil && err2 == nil {
			end = end.Add(23*time.Hour + 59*time.Minute + 59*time.Second)
			return start, end
		}
	}

	rangeKey := c.DefaultQuery("range", "month")
	return rangeDates(rangeKey)
}
