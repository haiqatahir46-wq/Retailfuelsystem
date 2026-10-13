import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../state/app_session.dart';
import 'main_tabs_flow.dart';
import 'route_guard.dart';
import 'signup_flow.dart';

/// Login screen, wrapped so its callbacks have a `context` with a
/// Navigator to push through. Stateless - it only routes onward, no local
/// state of its own.
///
/// TODO: onSignIn signs in the demo account (AppSession.signInDemo) with no
/// real check - there's no backend yet. Once you have an auth API,
/// validate email/password here first (e.g. show an error SnackBar on
/// failure) and only navigate on success.
class LoginFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onSignIn: (email, password) {
        if (!isTopRoute(context)) return;
        AppSessionScope.read(context).signInDemo(email: email);
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

/// Every Log Out button ends here: forgets the session, then returns to
/// Login with nothing behind it, so back can't reopen a signed-out screen.
void logOut(BuildContext context) {
  AppSessionScope.read(context).signOut();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginFlow()),
    (route) => false,
  );
}
