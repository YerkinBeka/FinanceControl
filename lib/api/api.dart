import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // LOCAL 
  // static const baseUrl = 'http://localhost:8080';

  // ANDROID 
  static const baseUrl = 'http://192.168.68.103:8080'; 


  static String? token;

  static Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

 
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    token = data['token'];
  }

  static Future<void> register({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 201) {
      throw Exception('Register failed');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Get profile failed');
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getBudget() async {
    final res = await http.get(
      Uri.parse('$baseUrl/budget'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Get budget failed');
    }

    return jsonDecode(res.body);
  }

  static Future<void> saveBudget(double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/budget'),
      headers: _headers(),
      body: jsonEncode({'amount': amount}),
    );

    if (res.statusCode != 200) {
      throw Exception('Save budget failed');
    }
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/auth/password'),
      headers: _headers(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Change password failed');
    }
  }

 
  static Future<Map<String, dynamic>> getSummary(
    String range, {
    String? start,
    String? end,
  }) async {
    String url = '$baseUrl/summary?range=$range';

    if (start != null && end != null) {
      url += '&start=$start&end=$end';
    }

    final res = await http.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Summary error');
    }

    return jsonDecode(res.body);
  }

  static Future<void> createCategory(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers(),
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 201) {
      throw Exception('Create category failed');
    }
  }

  
  static Future<List> getExpenses({
    required int categoryId,
    required String range,
    String? start,
    String? end,
  }) async {
    String url = '$baseUrl/expenses?category_id=$categoryId&range=$range';

    if (start != null && end != null) {
      url += '&start=$start&end=$end';
    }

    final res = await http.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Get expenses failed');
    }

    return jsonDecode(res.body);
  }

  static Future<void> createExpense({
    required int categoryId,
    required String note,
    required double amount,
    required String spentAt, 
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: _headers(),
      body: jsonEncode({
        'category_id': categoryId,
        'note': note,
        'amount': amount,
        'spent_at': spentAt,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Create expense failed');
    }
  }

  static Future<void> deleteExpense(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Delete expense failed');
    }
  }

  static Future<void> updateExpense({
    required int id,
    required int categoryId,
    required String note,
    required double amount,
    required String spentAt,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: _headers(),
      body: jsonEncode({
        'category_id': categoryId,
        'note': note,
        'amount': amount,
        'spent_at': spentAt,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Update expense failed');
    }
  }

  static Future<void> updateCategory({
    required int id,
    required String name,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers(),
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 200) {
      throw Exception('Update category failed');
    }
  }

  static void logout() {
  token = null;
  }


}
