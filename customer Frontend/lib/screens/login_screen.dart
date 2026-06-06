import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wedding_planning/screens/homeScreen.dart';
import 'package:wedding_planning/screens/pin_login_screen.dart';
import 'package:wedding_planning/screens/register_screen.dart';
import 'package:wedding_planning/services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthService().login(
        email: emailCtrl.text,
        password: passCtrl.text,
      );

      setState(() => _isLoading = false);

      if (result['status'] == 'success') {
        final user = result['user']; // ✅ Extract user info dynamically

        // Navigate to HomePage with dynamic userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _loginWithPin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PinLoginScreen(email: emailCtrl.text)),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFEFBBCF);

    return Scaffold(
      appBar: AppBar(title: const Text("Login"), backgroundColor: themeColor),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Email",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Password",
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loginWithPin,
              child: const Text("Login with PIN"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToRegister,
              child: const Text("Register New Account"),
            ),
          ],
        ),
      ),
    );
  }
}