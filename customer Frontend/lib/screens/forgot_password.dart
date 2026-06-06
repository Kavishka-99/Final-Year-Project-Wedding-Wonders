import 'package:flutter/material.dart';
import 'package:wedding_planning/services/auth_services.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  bool _loading = false;

  void _sendResetRequest() async {
    setState(() => _loading = true);
    final result = await AuthService().forgotPassword(emailCtrl.text);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? "Request sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFEFBBCF);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Enter your registered email to reset your password"),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email),
                hintText: "Email",
              ),
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _sendResetRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: const Text(
                    "Send Reset Link",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
