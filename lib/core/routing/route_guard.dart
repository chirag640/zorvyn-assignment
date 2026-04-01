import 'package:flutter/material.dart';

abstract class RouteGuard {
  const RouteGuard();

  bool canActivate(RouteSettings settings);

  Widget fallback({required BuildContext context});
}

