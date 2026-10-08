import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import 'main_tabs_flow.dart';
import 'signup_flow.dart';

/// Login screen, wrapped so its callbacks have a `context` with a
/// Navigator to push through. Stateless - it only routes onward, no local
/// state of its own.
///
/// TODO: onSignIn currently navigates straight to the main tabs with no
/// real check - there's no backend yet. Once you have an auth API,
/// validate email/password here first (e.g. show an error SnackBar on
/// failure) and only navigate on success.
class LoginFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onSignIn: (email, password) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // TODO: 'station-1' is a placeholder. Once a signed-in owner
            // can have a REAL selected station, pass that real id here
            // instead of a hardcoded one - a hardcoded id is exactly the
            // kind of thing that could leak one owner's data onto
            // another's screen.
            builder: (context) => const MainTabsFlow(stationId: 'station-1'),
          ),
        );
      },
      onCreateAccount: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SignupFlow()),
        );
      },
      // TODO: no password-reset flow/screen exists yet.
      onForgotPassword: null,
    );
  }

  const LoginFlow({super.key});
}
