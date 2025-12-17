# FinanceControl — Personal Expense Tracker

FinanceControl is a cross-platform personal finance management application developed using Flutter.
The application helps users track daily expenses, manage spending categories, and analyze their
financial activity over different time periods.

This project was developed as a Capstone Project for the Mobile App Development course.

---

##  Project Overview

The goal of FinanceControl is to provide users with a simple, intuitive, and efficient tool
to control their personal finances. Users can register, log in securely, create expense categories,
add expenses, and view summarized statistics for different date ranges (today, week, month).

The application supports both web and mobile platforms thanks to Flutter’s cross-platform capabilities.

---

##  Features

- User registration and authentication (JWT-based)
- Secure login and logout
- Expense category management
- Add, edit, and delete expenses
- Expense filtering by date range (today / week / month)
- Real-time expense summary
- User profile screen
- Cross-platform support (Web & Android)

---

##  Tech Stack

### Frontend
- Flutter (Dart)
- Material Design UI components

### Backend
- Go (Golang)
- RESTful API
- JWT authentication

### Database
- PostgreSQL

### Tools & Services
- Git & GitHub for version control
- Google Drive for deployment hosting
- Flutter Web for live demo

---

## Application Architecture
The application follows a client-server architecture.

The Flutter application is responsible for the user interface and user interactions.
It communicates with the backend via REST API using HTTP requests.
The backend processes requests, handles authentication, and interacts with the database.

Flutter App (UI)
      |
      | HTTP (REST API)
      v
Go Backend Server
      |
      v
PostgreSQL Database

User Manual:
https://drive.google.com/file/d/1GlbAD43Xl83NA03Ll-GfQcIjQ5FaKLSR/view?usp=sharing

Presentation:
https://docs.google.com/presentation/d/1euOo_VWUaYVit3OZHiyoPLjmdTbzAf7x/edit?usp=sharing&ouid=117090101939757068582&rtpof=true&sd=true

Technical Documentation:
https://drive.google.com/file/d/1f8FIIFTLu32cIBZxAUMa7OLNgL7_Ivcf/view?usp=sharing

Android AAB
https://drive.google.com/file/d/1y0YbdPgT-75AYiXmJxtolRO9YqjTyTb3/view?usp=sharing

GitHub Repisitory:
https://github.com/YerkinBeka/FinanceControl.git









