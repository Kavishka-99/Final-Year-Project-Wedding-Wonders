import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // ⚠️ FIX THIS URL BASED ON YOUR BACKEND
  final url = Uri.parse('http://localhost:3000/api/signin');

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // ================= VALIDATION =================
    if (email.isEmpty || password.isEmpty) {
      showMessage("All fields are required");
      return;
    }

    if (!email.contains("@")) {
      showMessage("Enter valid email");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("STATUS CODE: ${res.statusCode}");
      print("RESPONSE BODY: ${res.body}");

      final data = jsonDecode(res.body);

      // ================= SUCCESS =================
      if (res.statusCode == 200) {
        // 🔥 SAFE ID HANDLING (FIX FOR YOUR ERROR)
        final vendorId =
            data["id"] ?? data["vendor"]?["id"] ?? data["user"]?["id"];

        final name =
            data["name"] ?? data["vendor"]?["name"] ?? data["user"]?["name"];

        final emailRes =
            data["email"] ?? data["vendor"]?["email"] ?? data["user"]?["email"];

        if (vendorId == null) {
          showMessage("Invalid response from server");
          return;
        }

        // ================= SAVE DATA =================
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("vendorId", vendorId);
        await prefs.setString("name", name ?? "");
        await prefs.setString("email", emailRes ?? "");

        // ================= NAVIGATE =================
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VendorDashboardScreen(vendorId: vendorId),
          ),
        );
      }
      // ================= ERROR =================
      else {
        showMessage(data["message"] ?? "Login failed");
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      showMessage("Server error: $e");
    }

    setState(() => isLoading = false);
  }

  // ================= MESSAGE =================
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),

              const Text(
                "Vendor Login",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email, color: Colors.redAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.redAccent),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    showMessage("Forgot Password feature coming soon");
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LOGIN BUTTON
              isLoading
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: login,
                      child: const Text("Login"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
