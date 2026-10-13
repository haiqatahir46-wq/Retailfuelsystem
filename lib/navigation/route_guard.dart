import 'package:flutter/widgets.dart';

/// Whether the route holding [context] is the top route. Flows check this
/// before they push or pop, so a double tap can't open a screen twice (or
/// pop two screens): the first push or pop makes this route stop being the
/// top one straight away, and the second tap is ignored.
bool isTopRoute(BuildContext context) => ModalRoute.of(context)?.isCurrent ?? false;
