import 'package:flutter/material.dart';
import 'navigation/splash_flow.dart';
import 'state/app_session.dart';

void main() {
  runApp(const MyApp());
}

/// Owns the app's one [AppSession] for as long as the app runs.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _session = AppSession();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, not inside a route: every route the Navigator
    // pushes needs the same session.
    return AppSessionScope(
      session: _session,
      child: const MaterialApp(
        title: 'PARCO Fuel System',
        debugShowCheckedModeBanner: false,
        home: SplashFlow(),
      ),
    );
  }
}
