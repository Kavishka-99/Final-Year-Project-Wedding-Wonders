import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wedding_planning/screens/aiImageCreator.dart';
import 'package:wedding_planning/screens/budgetScreen.dart';
import 'package:wedding_planning/screens/findvendor.dart';
import 'package:wedding_planning/screens/guestScreen.dart';
import 'package:wedding_planning/screens/historyScreen.dart';
import 'package:wedding_planning/screens/profile_screen.dart';
import 'package:wedding_planning/screens/todoScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final themeColor = const Color(0xFFEFBBCF);

  String userName = "";
  String weddingCountdown = "";
  bool _isLoading = true;

  int? userId;
  bool _dataLoaded = false;

  late final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // =========================
  // LOAD USER ID
  // =========================
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null && !_dataLoaded) {
      await _fetchUserData();
      _dataLoaded = true;
    }
  }

  // =========================
  // FETCH USER DATA
  // =========================
  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/users/$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? weddingDate = data['wedding_date'];
        int daysLeft = 0;

        if (weddingDate != null && weddingDate.isNotEmpty) {
          final weddingDay = DateTime.parse(weddingDate);
          final now = DateTime.now();
          daysLeft = weddingDay.difference(now).inDays;
        }

        setState(() {
          userName = data['name'] ?? 'Guest';
          weddingCountdown =
              daysLeft >= 0 ? "$daysLeft days" : "Wedding done 💕";

          _isLoading = false;

          _screens.clear();
          _screens.addAll([
            _buildHomeContent(),
            AdvancedTodoScreen(userId: userId!),
            BudgetScreen(userId: userId!),
            ProfileScreen(userId: userId!),
          ]);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // =========================
  // HOME CONTENT
  // =========================
  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, $userName 👋",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Countdown: $weddingCountdown"),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _card(Icons.check, "To-Do", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdvancedTodoScreen(userId: userId!),
                    ),
                  );
                }),

                _card(Icons.money, "Budget", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetScreen(userId: userId!),
                    ),
                  );
                }),

                _card(Icons.people, "Guests", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GuestManagementScreen(),
                    ),
                  );
                }),

                _card(Icons.store, "Vendors", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FindVendorScreen()),
                  );
                }),

                _card(Icons.image, "AI Image", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiImagePage()),
                  );
                }),

                _card(Icons.history, "History", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(userId: userId!),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: themeColor),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text("Wedding Wonders"),
      ),

      body:
          _selectedIndex == 0 ? _buildHomeContent() : _screens[_selectedIndex],
    );
  }
}
