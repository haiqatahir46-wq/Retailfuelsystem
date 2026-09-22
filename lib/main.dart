import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/SplashScreen.dart';
import 'package:petrolpump_flutter/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _SplashGate(),
    ); // MaterialApp
  }
}

/// Shows SplashScreen, then moves on to LoginScreen by itself after a
/// short delay - tapping "Get Started" on the splash skips the wait
/// instead of making the user sit through it.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer(const Duration(seconds: 3), _goToLogin);
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    _autoAdvance?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onSignIn: (email, password) {
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onGetStarted: _goToLogin);
  }
}