import 'package:flutter/material.dart';
import '../screens/signup_screen.dart';
import '../state/app_session.dart';
import 'route_guard.dart';
import 'stations_added_flow.dart';

/// Signup screen, wrapped the same way as LoginFlow. Create Account creates
/// the account in the session (AppSession.signUp: the owner plus the
/// stations implied by the form, each with a fresh id) and moves on to
/// StationsAddedFlow, which lists those stations from the session.
class SignupFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignupScreen(
      onBack: () => Navigator.of(context).pop(),
      onSignIn: () => Navigator.of(context).pop(), // "Already have an account?"
      onCreateAccount: ({
        required usernameOrGmail,
        required password,
        required dateOfBirth,
        required stationName,
        required stationCount,
      }) {
        if (!isTopRoute(context)) return;
        AppSessionScope.read(context).signUp(
          usernameOrEmail: usernameOrGmail,
          stationName: stationName,
          stationCount: stationCount,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StationsAddedFlow()),
        );
      },
    );
  }

  const SignupFlow({super.key});
}
