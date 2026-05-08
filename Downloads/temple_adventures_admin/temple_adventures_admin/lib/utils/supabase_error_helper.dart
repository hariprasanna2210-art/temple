import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/logging.dart';

/// Helper class to convert Supabase errors to user-friendly messages
class SupabaseErrorHelper {
  /// Converts a Supabase exception to a user-friendly message
  static String getSupabaseErrorMessage(dynamic error) {
    // Handle PostgrestException (API errors)
    if (error is PostgrestException) {
      Log.w('SupabaseErrorHelper: handling PostgrestException: ${error.code} - ${error.message}');

      // Extract nested message if it's a JSON string
      String message = error.message;
      try {
        // Try to parse nested JSON message
        if (message.contains('{') && message.contains('message')) {
          final jsonMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(message);
          if (jsonMatch != null) {
            message = jsonMatch.group(1)!;
          }
        }
      } catch (_) {
        // If parsing fails, use original message
      }

      // Check for authentication errors (401)
      if (error.code == '401') {
        // Check for invalid API key specifically
        if (message.contains('Invalid API key') || message.contains('anon') || message.contains('service_role')) {
          return 'Invalid API configuration. Please check your Supabase API key.';
        }
        return 'Authentication failed. Please check your API configuration.';
      }

      // Check for permission errors
      if (error.code == '42501') {
        return 'You do not have permission to perform this action.';
      }

      // Check for not found errors
      if (error.code == 'PGRST116') {
        return 'The requested resource was not found.';
      }

      // Check for invalid API key in message (even if code is not 401)
      if (message.contains('Invalid API key') || message.contains('anon') || message.contains('service_role')) {
        return 'Invalid API configuration. Please check your Supabase API key.';
      }

      // Return the extracted message if it's user-friendly
      if (message.isNotEmpty &&
          !message.contains('PostgrestException') &&
          !message.contains('{') &&
          !message.contains('code')) {
        return message;
      }

      return 'A database error occurred. Please try again.';
    }

    // Handle AuthException (Supabase Auth errors from gotrue)
    if (error is AuthException) {
      Log.w('SupabaseErrorHelper: handling AuthException: ${error.message}');

      // Check message for 401 or authentication errors
      if (error.message.contains('401') ||
          error.message.contains('Unauthorized') ||
          error.message.contains('Invalid')) {
        return 'Authentication failed. Please log in again.';
      }

      return error.message.isNotEmpty ? error.message : 'An authentication error occurred.';
    }

    // Handle string errors
    if (error is String) {
      if (error.contains('Invalid API key') || error.contains('401') || error.contains('Unauthorized')) {
        return 'Invalid API configuration. Please contact support.';
      }

      if (error.contains('PostgrestException')) {
        return 'A database error occurred. Please try again.';
      }

      return error;
    }

    // Log unexpected error types
    Log.w('SupabaseErrorHelper: unexpected error type: $error');
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is a configuration/authentication error
  static bool isConfigurationError(dynamic error) {
    if (error is PostgrestException) {
      return error.code == '401' || error.message.contains('Invalid API key');
    }

    if (error is String) {
      return error.contains('Invalid API key') || error.contains('401') || error.contains('Unauthorized');
    }

    return false;
  }

  /// Get error code for Sentry context
  static String? getErrorCode(dynamic error) {
    if (error is PostgrestException) {
      return error.code?.toString();
    }

    if (error is AuthException) {
      // AuthException doesn't have status, extract from message if possible
      final codeMatch = RegExp(r'\b(\d{3})\b').firstMatch(error.message);
      return codeMatch?.group(1);
    }

    return null;
  }
}
