import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'addServices.dart';
import 'chat.dart';
import 'myworks.dart';
import 'subscrptionScreen.dart';
import 'vendorBookings.dart';
import 'signinPage.dart';

class VendorDashboardScreen extends StatefulWidget {
  final int vendorId;

  const VendorDashboardScreen({Key? key, required this.vendorId})
    : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  // ================= REAL DATA STATE =================
  String name = "Loading...";
  String email = "Loading...";
  double rating = 0.0;

  int bookings = 0;
  int services = 0;
  String earnings = "Rs 0";

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchVendorData();

    // 🔥 AUTO REFRESH EVERY 10 SECONDS
    timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchVendorData();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ================= FETCH DATA =================
  Future<void> fetchVendorData() async {
    try {
      final url = Uri.parse(
        "http://10.0.2.2:3000/api/vendor/dashboard/${widget.vendorId}",
      );

      final res = await http.get(url);

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;

        setState(() {
          name = data["name"] ?? "No Name";
          email = data["email"] ?? "No Email";

          rating = double.tryParse(data["rating"].toString()) ?? 0.0;

          bookings = data["bookings"] ?? 0;
          services = data["services"] ?? 0;

          earnings = "Rs ${data["earnings"] ?? 0}";
        });
      } else {
        print("API Error: ${res.statusCode}");
      }
    } catch (e) {
      print("Dashboard error: $e");
    }
  }

  // ================= LOGOUT =================
  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Vendor Dashboard"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // ================= PROFILE =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.black87],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.red),
                  ),
                  const SizedBox(width: 15),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "⭐ Rating: $rating",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= STATS =================
            Row(
              children: [
                _stat("Bookings", bookings.toString()),
                _stat("Services", services.toString()),
                _stat("Earnings", earnings),
              ],
            ),

            const SizedBox(height: 20),

            // ================= ACTIONS =================
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _card("Add Service", Icons.add, () {
                  go(AddServiceScreen(vendorId: widget.vendorId));
                }),

                _card("Bookings", Icons.book, () {
                  go(VendorBookingsScreen(vendorId: widget.vendorId));
                }),

                _card("Chat", Icons.chat, () {
                  go(ChatPage(vendorId: widget.vendorId, customerId: 1));
                }),

                _card("Subscription", Icons.star, () {
                  go(PricingPlanScreen(vendorId: widget.vendorId));
                }),

                _card("My Works", Icons.work, () {
                  go(MyWorksPage(vendorId: widget.vendorId));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATS WIDGET =================
  Widget _stat(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ================= CARD WIDGET =================
  Widget _card(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}
