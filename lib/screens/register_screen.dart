import 'package:flutter/material.dart';
import '../ui/app_styles.dart';
import '../api/api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final repeatPassCtrl = TextEditingController();

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    try {
      await Api.register(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully')),
      );

      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('Register')),
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
                  const Text('Create a new account', style: subtitleStyle),
                  const SizedBox(height: 16),
                  _emailField(),
                  const SizedBox(height: 16),
                  _passwordField(),
                  const SizedBox(height: 16),
                  _repeatPasswordField(),
                  const SizedBox(height: 24),
                  _actions(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => const Text('Create Account', style: titleStyle);

  Widget _emailField() => TextFormField(
        controller: emailCtrl,
        decoration: inputStyle('Email'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email is required';
          if (!v.contains('@')) return 'Invalid email';
          return null;
        },
      );

  Widget _passwordField() => TextFormField(
        controller: passCtrl,
        obscureText: true,
        decoration: inputStyle('Password'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password is required';
          if (v.length < 6) return 'Min 6 characters';
          return null;
        },
      );

  Widget _repeatPasswordField() => TextFormField(
        controller: repeatPassCtrl,
        obscureText: true,
        decoration: inputStyle('Repeat Password'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Repeat password is required';
          if (v != passCtrl.text) return 'Passwords do not match';
          return null;
        },
      );

  Widget _actions() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: buttonStyle,
          onPressed: register,
          child: const Text(
            'Register',
            style: buttonTextStyle,
          ),
        ),
      );

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    repeatPassCtrl.dispose();
    super.dispose();
  }
}
