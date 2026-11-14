import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../state/app_session.dart';

/// Runs [action], a session change that may go to the server, for a flow.
///
/// With the server, a spinner covers the screen until it finishes (unless
/// [showProgress] is false), which also stops a second tap starting it
/// again, and a refusal or a network failure is shown as a SnackBar with
/// the [ApiException]'s message. Returns whether it succeeded, so the flow
/// only moves on (closes the form, opens the next screen) when it did.
///
/// On demo data there is nothing to wait for or to fail, so it just runs.
Future<bool> runServerAction(
  BuildContext context,
  Future<void> Function() action, {
  bool showProgress = true,
}) async {
  if (!AppSessionScope.read(context).usesServer) {
    await action();
    return true;
  }
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (showProgress) {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ));
  }
  try {
    await action();
    return true;
  } on ApiException catch (error) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  } finally {
    // Navigator.pop ignores the spinner's PopScope (that only stops the
    // back button), so this always closes it.
    if (showProgress) navigator.pop();
  }
}
