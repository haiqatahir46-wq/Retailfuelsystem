import 'package:flutter/material.dart';
import 'navigation/splash_flow.dart';
import 'services/api_client.dart';
import 'state/app_session.dart';

/// Run on the built-in demo data instead of the server:
/// `flutter run --dart-define=DEMO_DATA=true`. Handy without the server
/// (server/) running; nothing is saved.
const kUseDemoData = bool.fromEnvironment('DEMO_DATA');

void main() {
  runApp(const MyApp());
}

/// Owns the app's one [AppSession] for as long as the app runs. By default
/// it talks to the API server (see ApiClient for where it looks); [session]
/// lets a test supply its own instead.
class MyApp extends StatefulWidget {
  final AppSession? session;

  const MyApp({super.key, this.session});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppSession _session = widget.session ?? AppSession(api: kUseDemoData ? null : ApiClient());

  @override
  void dispose() {
    // A session passed in belongs to whoever made it.
    if (widget.session == null) _session.dispose();
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
