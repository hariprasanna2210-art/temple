import 'package:flutter/widgets.dart';
import 'package:temple_adventures_admin/main.dart';
import 'package:temple_adventures_admin/services/logging.dart';
import 'package:temple_adventures_admin/theme.dart';

/// A mixin for StatefulWidget States that automatically resets the system UI overlay style
/// (e.g., status bar color) when the route is pushed or popped next.
///
/// To use it:
/// 1. Ensure `routeObserver` is properly set up in your `MaterialApp` (see `main.dart`).
/// 2. Make your State class use this mixin:
///    `class _MyScreenState extends State<MyScreen> with RouteAware, StatusBarHandlerMixin { ... }`
///    (Note: `RouteAware` is still needed by the mixin's constraints, but its methods are handled by the mixin)
mixin StatusBarHandlerMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // This method is called when the current route has been pushed.
    // Log.i("${T.toString()} (StatusBarHandlerMixin): didPush - Resetting status bar UI");
    // systemUIOverlayStyle();
  }

  @override
  void didPopNext() {
    // This method is called when the top route has been popped off,
    // and the current route is shown again.
    Log.i("${T.toString()} (StatusBarHandlerMixin): didPopNext - Resetting status bar UI");
    Future.delayed(Duration(milliseconds: 400), () => systemUIOverlayStyle());
  }

  // Optional: You can provide empty implementations for other RouteAware methods
  // if you don't need specific logic for them in the screens using this mixin.
  // However, RouteAware itself defines them, so classes using this mixin implicitly have them.
  @override
  void didPop() {
    // Called when the current route has been popped off.
    // Log.i("${T.toString()} (StatusBarHandlerMixin): didPop");
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and the current route is no longer visible.
    // Log.i("${T.toString()} (StatusBarHandlerMixin): didPushNext");
  }
}
