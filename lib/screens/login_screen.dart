import 'package:flutter/material.dart';
import '../ui/app_styles.dart';
import '../api/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      await Api.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  void goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: cardDecoration,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const SizedBox(height: 10),
                  const Text('Login to your account', style: subtitleStyle),
                  const SizedBox(height: 16),
                  _emailField(),
                  const SizedBox(height: 16),
                  _passwordField(),
                  const SizedBox(height: 24),
                  _actions(),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: goToRegister,
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => const Text('Welcome Back', style: titleStyle);

  Widget _emailField() => TextFormField(
        controller: emailCtrl,
        decoration: inputStyle('Email'),
        validator: (v) =>
            v == null || !v.contains('@') ? 'Invalid email' : null,
      );

  Widget _passwordField() => TextFormField(
        controller: passCtrl,
        obscureText: true,
        decoration: inputStyle('Password'),
        validator: (v) =>
            v != null && v.length < 6 ? 'Min 6 characters' : null,
      );

  Widget _actions() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: login,
          child: const Text(
            'Login',
            style: buttonTextStyle,
          ),
        ),
      );

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
