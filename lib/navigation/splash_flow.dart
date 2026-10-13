import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import 'login_flow.dart';

/// App entry point's first screen. Shows SplashScreen, then moves on to
/// LoginFlow by itself after a short delay - tapping "Get Started" on the
/// splash skips the wait instead of making the user sit through it.
class SplashFlow extends StatefulWidget {
  @override
  State<SplashFlow> createState() => _SplashFlowState();

  const SplashFlow({super.key});
}

class _SplashFlowState extends State<SplashFlow> {
  Timer? _autoAdvance;

  // Set by the first of the timer and the "Get Started" tap, so a tap that
  // lands just as the timer fires can't push Login twice.
  bool _navigated = false;

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
    if (!mounted || _navigated) return;
    _navigated = true;
    // pushReplacement, not push: the splash screen should never be
    // reachable again via the back button once we've moved past it.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginFlow()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onGetStarted: _goToLogin);
  }
}
