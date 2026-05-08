import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart'
    show Breadcrumb, Hint, Sentry, SentryEvent, SentryFlutter, SentryLevel, SentryMessage, SentryUser;

import 'logging_stream.dart' hide LogEvent;

bool? activateSentryWrapper;

/// Helper class for Sentry error logging with additional context
class SentryHelper {
  /// Set user context for Sentry
  static void setUser({String? userId, String? username, String? email, Map<String, dynamic>? data}) {
    if (!kDebugMode) {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: userId,
          username: username,
          email: email,
          data: data,
        ));
      });
    }
  }

  /// Clear user context
  static void clearUser() {
    if (!kDebugMode) {
      Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    }
  }

  /// Add breadcrumb with context
  static void addBreadcrumb(String message, {SentryLevel level = SentryLevel.info, Map<String, dynamic>? data}) {
    if (!kDebugMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          level: level,
          data: data,
        ),
      );
    }
  }

  /// Capture exception with additional context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? extra,
    String? tag,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!kDebugMode) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'extra': extra ?? {},
          'tag': tag,
        }),
      );
    }
  }

  /// Capture message with context
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
    String? tag,
  }) async {
    if (!kDebugMode) {
      await Sentry.captureMessage(
        message,
        level: level,
        hint: Hint.withMap({
          'extra': extra ?? {},
          'tag': tag,
        }),
      );
    }
  }
}

// ignore: non_constant_identifier_names
final Log = Logger(
  filter: CustomFilter(),
  printer: CustomPrinter(),
  output: CustomOutput(),
);

class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true; // in debug mode, log everything
    } else {
      return event.level.index >= Level.info.index; // in release mode, only log >= info
    }
  }
}

class CustomPrinter extends SimplePrinter {
  CustomPrinter() : super(colors: false);

  @override
  List<String> log(LogEvent event) {
    if (!kDebugMode) {
      // in release mode, log info messages up to warning messages as breadcrumbs
      if (event.level.index >= Level.info.index && event.level.index < Level.error.index) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: event.message.toString(),
            level: _toSentryLevel(event.level),
          ),
        );
      }
      // in release mode, send error or higher severity events to sentry
      if (event.level.index >= Level.error.index) {
        Sentry.captureEvent(
          SentryEvent(
            throwable: event.error,
            message: SentryMessage('${event.message}'),
            level: _toSentryLevel(event.level),
          ),
          stackTrace: event.stackTrace,
        );
      }
    }
    final lines = super.log(event);
    if (event.stackTrace != null) {
      lines.addAll(event.stackTrace.toString().split('\n'));
    }
    return lines;
  }
}

class CustomOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (kDebugMode) {
      // in debug mode, log to console
      for (final line in event.lines) {
        // ignore: avoid_print
        print(line);
      }
    }
  }
}

SentryLevel _toSentryLevel(Level l) {
  switch (l) {
    case Level.warning:
      return SentryLevel.warning;
    case Level.error:
      return SentryLevel.error;
    case Level.info:
      return SentryLevel.info;
    case Level.fatal:
      return SentryLevel.fatal;
    case Level.debug:
    default:
      return SentryLevel.debug;
  }
}

Future<void> wrapApp(FutureOr<void> Function() runApp) async {
  // Subscribe to log streams (used by empty_to_null_hooks.dart)
  logStreams.warningStreamController.stream.listen((event) {
    Log.w(event.message, error: event.error, stackTrace: event.stackTrace, time: event.time);
  });
  logStreams.errorStreamController.stream.listen((event) {
    Log.e(event.message, error: event.error, stackTrace: event.stackTrace, time: event.time);
  });

  // Load environment variables from the .env file
  await dotenv.load(fileName: '.env');
  if (kDebugMode) return runApp();
  
  // Get app version dynamically
  String releaseVersion = 'temple_adventures_admin@unknown';
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    releaseVersion = 'temple_adventures_admin@${packageInfo.version}+${packageInfo.buildNumber}';
  } catch (e) {
    debugPrint('Failed to get package info for Sentry: $e');
  }
  
  await SentryFlutter.init(
    (options) {
      if (kDebugMode) {
        options.dsn = dotenv.env['SENTRY_DSN'];
        options.tracesSampler = (_) => activateSentryWrapper ?? false ? 1.0 : 0.0;
      } else {
        options.dsn = dotenv.env['SENTRY_DSN'];
        options.tracesSampler = (_) => activateSentryWrapper ?? false ? 1.0 : 0.0;
      }

      options.maxBreadcrumbs = 200; // By default, SentryFlutter will keep up to 100 breadcrumbs.

      // Set release and environment dynamically
      options.release = releaseVersion;
      options.environment = kDebugMode ? 'development' : 'production';

      // Configure beforeSend to sanitize user data
      options.beforeSend = (event, hint) async {
        if (activateSentryWrapper ?? true) {
          SentryUser? user = event.user;
          if (user != null) {
            user = SentryUser(
              id: user.id,
              username: null,
              email: null,
              ipAddress: null,
              data: user.data,
              geo: null,
              name: null,
            );
          }
          return event.copyWith(user: user);
        } else {
          return null;
        }
      };
    },
    appRunner: runApp,
  );
}
