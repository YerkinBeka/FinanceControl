import 'package:flutter/material.dart';
import '../ui/app_styles.dart';
import '../api/api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;

  String email = '';
  double budget = 0;
  double spent = 0;
  double remaining = 0;

  final budgetCtrl = TextEditingController();
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    budgetCtrl.dispose();
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() => loading = true);
    try {
      final me = await Api.getMe();
      email = me['email'] ?? '';

      final b = await Api.getBudget();
      budget = (b['budget'] as num).toDouble();
      spent = (b['spent'] as num).toDouble();
      remaining = (b['remaining'] as num).toDouble();

      budgetCtrl.text = budget.toStringAsFixed(0);
    } catch (_) {}
    setState(() => loading = false);
  }

  void saveBudget() async {
    final value = double.tryParse(budgetCtrl.text);
    if (value == null || value < 0) return;

    await Api.saveBudget(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved')),
    );
    loadProfile();
  }

  void changePassword() async {
    if (oldPassCtrl.text.trim().isEmpty) return;
    if (newPassCtrl.text.trim().length < 6) return;

    try {
      await Api.changePassword(
        oldPassword: oldPassCtrl.text.trim(),
        newPassword: newPassCtrl.text.trim(),
      );

      if (!mounted) return;
      oldPassCtrl.clear();
      newPassCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong old password')),
      );
    }
  }

  void logout() {
    Api.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (_) => false,
    );
  }

  Widget _infoCard(String title, String value) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: subtitleStyle),
            Text(value, style: titleStyle),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account', style: titleStyle),
                        const SizedBox(height: 10),
                        Text('Email: $email', style: subtitleStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Budget', style: titleStyle),
                        const SizedBox(height: 12),
                        TextField(
                          controller: budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: inputStyle('Budget amount (₸)'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: saveBudget,
                            child: const Text('Save budget', style: buttonTextStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoCard('Spent this month', '${spent.toStringAsFixed(2)} ₸'),
                  _infoCard('Remaining', '${remaining.toStringAsFixed(2)} ₸'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change Password', style: titleStyle),
                        const SizedBox(height: 12),
                        TextField(
                          controller: oldPassCtrl,
                          obscureText: true,
                          decoration: inputStyle('Old password'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPassCtrl,
                          obscureText: true,
                          decoration: inputStyle('New password'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: changePassword,
                            child: const Text('Update password', style: buttonTextStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: buttonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      onPressed: logout,
                      child: const Text('Logout', style: buttonTextStyle),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
