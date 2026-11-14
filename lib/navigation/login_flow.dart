import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../state/app_session.dart';
import 'main_tabs_flow.dart';
import 'route_guard.dart';
import 'server_action.dart';
import 'signup_flow.dart';

/// Login screen, wrapped so its callbacks have a `context` with a
/// Navigator to push through. Stateless - it only routes onward, no local
/// state of its own.
///
/// Sign In goes through AppSession.signIn: with the server, the email and
/// password are checked against the users table and the owner's data is
/// loaded, and a wrong password (or an unreachable server) shows the
/// server's message instead of moving on; on demo data any login is the
/// demo account.
class LoginFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onSignIn: (email, password) async {
        if (!isTopRoute(context)) return;
        final session = AppSessionScope.read(context);
        final signedIn = await runServerAction(context, () => session.signIn(email: email, password: password));
        if (!signedIn || !context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainTabsFlow()),
        );
      },
      onCreateAccount: () {
        if (!isTopRoute(context)) return;
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

/// Every Log Out button ends here: forgets the session (and, with the
/// server, ends it there in the background), then returns to Login with
/// nothing behind it, so back can't reopen a signed-out screen.
/// Any SnackBar still showing goes too: it belongs to the old session (the
/// app-wide ScaffoldMessenger would otherwise carry "Petrol threshold
/// set..." onto Login).
void logOut(BuildContext context) {
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  AppSessionScope.read(context).signOut();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginFlow()),
    (route) => false,
  );
}
