import 'package:firebase_auth/firebase_auth.dart';
import '../services/logging.dart';

/// Helper class to convert Firebase Auth error codes to user-friendly messages
class FirebaseAuthErrorHelper {
  // Application-level error messages
  static const String errorUserNotAuthorized = 'User not authorized to use the app';
  static const String errorPhoneNumberMissing = 'Phone number missing.';
  static const String errorVerificationIdMissing = 'Verification ID missing. Please request a new OTP.';
  static const String errorUserNotVerified = 'User not verified yet.';

  /// Converts a Firebase Auth exception or error string to a user-friendly message
  /// This method handles both Firebase errors and application-level error messages
  static String getAuthErrorMessage(dynamic error) {
    // If it's a FirebaseAuthException, use the error code
    if (error is FirebaseAuthException) {
      Log.w('FirebaseAuthErrorHelper: handling FirebaseAuthException: ${error.code} - ${error.message}');
      return _getMessageFromCode(error.code);
    }

    // Handle PlatformException (common in Flutter)
    if (error.toString().contains('PlatformException')) {
      Log.w('FirebaseAuthErrorHelper: handling PlatformException: $error');
      // Try to extract error code from PlatformException
      final codeMatch = RegExp(r'code:\s*([^,]+)').firstMatch(error.toString());
      if (codeMatch != null) {
        final code = codeMatch.group(1)!.trim();
        return _getMessageFromCode(code);
      }
      // Try to extract message
      final messageMatch = RegExp(r'message:\s*([^,]+)').firstMatch(error.toString());
      if (messageMatch != null) {
        final message = messageMatch.group(1)!.trim();
        if (message.contains('invalid-verification-code') || message.contains('invalid-verification-id')) {
          return _getMessageFromCode(message.contains('invalid-verification-code') ? 'invalid-verification-code' : 'invalid-verification-id');
        }
      }
    }

    // If it's a string, check if it's already a friendly message first
    if (error is String) {
      // Check if it's one of our application-level constants (friendly messages)
      if (error == errorUserNotAuthorized || 
          error == errorPhoneNumberMissing || 
          error == errorVerificationIdMissing || 
          error == errorUserNotVerified) {
        return error;
      }

      // Early return for friendly messages (already converted messages)
      // Don't log these as they're expected friendly messages
      if (!error.contains('firebase_auth/') && 
          !error.contains('Error:') && 
          !error.contains('invalid-') &&
          !error.contains('Exception') &&
          !error.contains('PlatformException')) {
        // This might be a friendly message, but log it if it's the generic one
        if (error == 'An error occurred. Please try again.') {
          Log.w('FirebaseAuthErrorHelper: received generic error message - original error may be lost');
        }
        return error;
      }

      // Log only for actual errors that need conversion
      Log.w('FirebaseAuthErrorHelper: handling error string: $error');

      // Check if the string contains a Firebase error code
      final codeMatch = RegExp(r'\[firebase_auth/([^\]]+)\]').firstMatch(error);
      if (codeMatch != null) {
        return _getMessageFromCode(codeMatch.group(1)!);
      }

      // Try to extract error code from common patterns
      if (error.contains('invalid-verification-code')) {
        return 'The OTP you entered is incorrect. Please check and try again.';
      }
      if (error.contains('invalid-verification-id')) {
        return 'The verification code has expired. Please request a new OTP.';
      }
      if (error.contains('session-expired')) {
        return 'Your session has expired. Please request a new OTP.';
      }
      if (error.contains('too-many-requests')) {
        return 'Too many attempts. Please try again later.';
      }
      if (error.contains('network-request-failed') || error.contains('network_error')) {
        return 'Network error. Please check your internet connection and try again.';
      }
      if (error.contains('timeout') || error.contains('TimeoutException')) {
        return 'Request timed out. Please check your internet connection and try again.';
      }
    }

    // Log unexpected error types with full details
    Log.w('FirebaseAuthErrorHelper: unexpected error type: ${error.runtimeType} - $error');
    // Default fallback message
    return 'An error occurred. Please try again.';
  }

  /// Maps Firebase Auth error codes to user-friendly messages
  static String _getMessageFromCode(String code) {
    switch (code) {
      // OTP/Verification errors
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please check and try again.';
      case 'invalid-verification-id':
        return 'The verification code has expired. Please request a new OTP.';
      case 'session-expired':
        return 'Your session has expired. Please request a new OTP.';
      case 'code-expired':
        return 'The OTP has expired. Please request a new one.';

      // Phone number errors
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please check and try again.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';

      // Network errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';

      // Rate limiting
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      // User errors
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'User not found. Please check your phone number.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';

      // Credential errors
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';

      // Default case
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
