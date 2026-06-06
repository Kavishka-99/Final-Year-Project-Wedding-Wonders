import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_planning/screens/login_screen.dart';
import 'package:wedding_planning/services/auth_services.dart';
import 'package:wedding_planning/widgets/custom_inputs.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final partnerEmailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  DateTime? weddingDate;

  bool _loading = false;
  bool _obscure = true;

  void _pickWeddingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
    );
    if (picked != null) {
      setState(() => weddingDate = picked);
    }
  }

  void _register() async {
    if (weddingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select wedding date')),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService().registerExtended(
      name: nameCtrl.text,
      email: emailCtrl.text,
      password: passCtrl.text,
      phone: phoneCtrl.text,
      weddingDate: weddingDate!.toIso8601String(),
      partnerEmail: partnerEmailCtrl.text,
      pin: pinCtrl.text,
    );
    setState(() => _loading = false);

    if (result['message'] == 'User registered') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFEFBBCF);
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: themeColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomInput(
              controller: nameCtrl,
              hintText: "Full Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: emailCtrl,
              hintText: "Email",
              icon: Icons.email,
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: phoneCtrl,
              hintText: "Phone",
              icon: Icons.phone,
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: partnerEmailCtrl,
              hintText: "Partner's Email",
              icon: Icons.people_alt,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickWeddingDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF8E3A59)),
                    const SizedBox(width: 16),
                    Text(
                      weddingDate == null
                          ? "Select Wedding Date"
                          : DateFormat('MMMM d, yyyy').format(weddingDate!),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomInput(
              controller: pinCtrl,
              hintText: "4-digit PIN",
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF8E3A59)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                hintText: "Password",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text("Already have an account? Sign in"),
            ),
          ],
        ),
      ),
    );
  }
}

extension on AuthService {
  registerExtended({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String weddingDate,
    required String partnerEmail,
    required String pin,
  }) {}
}
