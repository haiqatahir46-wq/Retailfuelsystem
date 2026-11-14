import 'package:flutter/material.dart';
import '../screens/signup_screen.dart';
import '../state/app_session.dart';
import 'route_guard.dart';
import 'server_action.dart';
import 'stations_added_flow.dart';

/// Signup screen, wrapped the same way as LoginFlow. Create Account creates
/// the account through the session (AppSession.signUp: the owner plus the
/// stations implied by the form) and moves on to StationsAddedFlow, which
/// lists those stations from the session. With the server the account is
/// created in the database and signs in with an email address, so the form
/// asks for one; a refusal (e.g. the email is taken) shows the server's
/// message and stays on the form.
class SignupFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.read(context);
    return SignupScreen(
      requireEmail: session.usesServer,
      onBack: () => Navigator.of(context).pop(),
      onSignIn: () => Navigator.of(context).pop(), // "Already have an account?"
      onCreateAccount: ({
        required usernameOrGmail,
        required password,
        required dateOfBirth,
        required stationName,
        required stationCount,
      }) async {
        if (!isTopRoute(context)) return;
        final created = await runServerAction(
          context,
          () => session.signUp(
            usernameOrEmail: usernameOrGmail,
            password: password,
            stationName: stationName,
            stationCount: stationCount,
          ),
        );
        if (!created || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StationsAddedFlow()),
        );
      },
    );
  }

  const SignupFlow({super.key});
}
