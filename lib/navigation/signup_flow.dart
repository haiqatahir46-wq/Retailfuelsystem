import 'package:flutter/material.dart';
import '../screens/signup_screen.dart';
import 'stations_added_flow.dart';

/// Signup screen, wrapped the same way as LoginFlow. Collects data and
/// hands it to StationsAddedFlow, which is the widget that actually needs
/// to own and mutate a stations list.
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StationsAddedFlow(
              stationName: stationName,
              stationCount: stationCount,
            ),
          ),
        );
      },
    );
  }

  const SignupFlow({super.key});
}
