import 'package:flutter/material.dart';
import 'package:vendors_wedding_wonders/dashboard.dart';
import 'package:vendors_wedding_wonders/pay.dart';
import 'package:vendors_wedding_wonders/signinPage.dart';
import 'package:vendors_wedding_wonders/signupPage.dart';
import 'package:vendors_wedding_wonders/subscrptionScreen.dart';
import 'package:vendors_wedding_wonders/welcomepage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: WelcomePage(),
    );
  }
}
