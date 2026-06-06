import 'package:flutter/material.dart';
import 'package:wedding_planning/screens/homeScreen.dart';
import 'package:wedding_planning/screens/login_screen.dart';
import 'package:wedding_planning/services/auth_services.dart';

class PinLoginScreen extends StatefulWidget {
  final String email;
  const PinLoginScreen({super.key, required this.email});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final pinCtrl = TextEditingController();
  int _attempts = 0;
  bool _isLoading = false;

  Future<void> _loginWithPin() async {
    setState(() => _isLoading = true);

    final result = await AuthService().loginWithPin(
      email: widget.email,
      pin: pinCtrl.text,
    );

    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      final user = result['user'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      setState(() => _attempts++);

      if (_attempts >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Too many failed attempts. Returning to login."),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid PIN")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFEFBBCF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter PIN"),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your 4-digit PIN",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinCtrl,
              maxLength: 4,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "PIN",
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _loginWithPin,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
