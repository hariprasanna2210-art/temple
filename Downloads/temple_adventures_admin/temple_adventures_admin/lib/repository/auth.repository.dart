import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firebase_auth_error_helper.dart';
import '../services/logging.dart';

/// Repository for Firebase Authentication operations.
/// Handles phone number-based OTP authentication flow.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current Firebase user (if signed in).
  /// Returns null if no user is currently authenticated.
  User? getCurrentUser() => _auth.currentUser;

  /// Initiates phone number authentication flow.
  /// 
  /// **Flow:**
  /// 1. Sends OTP to the provided phone number
  /// 2. Provides callbacks for different scenarios:
  ///    - `onCodeSent`: OTP was sent successfully (user must enter OTP manually)
  ///    - `onTimeout`: SMS autofill timed out (user must enter OTP manually)
  ///    - `onFailure`: Authentication failed
  ///    - `onSuccess`: Legacy callback (not actively used)
  /// 
  /// **Note:** Auto-verification is disabled. Users must manually enter the OTP.
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String verificationId) onTimeout,
    required Function(String error) onFailure,
    required Function onSuccess, // Legacy callback - kept for interface compatibility
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        timeout: const Duration(seconds: 60),
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification is disabled - ignore this callback
          // User must manually enter the OTP
          Log.i('Auto-verification triggered but disabled - user must enter OTP manually');
        },
        verificationFailed: (FirebaseAuthException e) {
          onFailure(FirebaseAuthErrorHelper.getAuthErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout(verificationId);
        },
      );
    } catch (e) {
      onFailure(FirebaseAuthErrorHelper.getAuthErrorMessage(e));
    }
  }

  /// Verifies the OTP entered by the user.
  /// 
  /// **Input Validation:**
  /// - Verification ID must not be empty
  /// - OTP must be exactly 6 digits
  /// 
  /// **Error Handling:**
  /// - User input errors (wrong OTP, expired session) are logged as warnings
  /// - System errors (network, quota, etc.) are logged as errors and sent to Sentry
  /// 
  /// **Flow:**
  /// 1. Validate inputs
  /// 2. Create PhoneAuthCredential with verification ID and OTP
  /// 3. Sign in with credential
  /// 4. Call onSuccess if successful, onFailure if error occurs
  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
    required Function onSuccess,
    required Function(String error) onFailure,
  }) async {
    try {
      // Validate inputs before making API call
      if (verificationId.isEmpty) {
        onFailure('Verification ID is missing. Please request a new OTP.');
        return;
      }
      if (otp.isEmpty || otp.length != 6) {
        onFailure('Please enter a valid 6-digit OTP.');
        return;
      }

      Log.i('Verifying OTP with verification ID: ${verificationId.substring(0, 10)}...');

      // Create credential from verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with the credential
      await _auth.signInWithCredential(credential);

      // After successful signInWithCredential, currentUser should always be set
      Log.i('OTP verification successful');
      onSuccess();
    } on FirebaseAuthException catch (e) {
      // Differentiate between user input errors and system errors for better logging
      // User input errors (wrong OTP) should be logged as warnings, not errors
      // System errors (network, quota, etc.) should be logged as errors and sent to Sentry
      final isUserInputError =
          e.code == 'invalid-verification-code' || e.code == 'invalid-verification-id' || e.code == 'session-expired';

      if (isUserInputError) {
        Log.w('AuthRepository: User input error during OTP verification: ${e.code}');
      } else {
        Log.e(
          'AuthRepository: FirebaseAuthException during OTP verification: ${e.code}',
          error: e,
          stackTrace: StackTrace.current,
        );
      }
      onFailure(FirebaseAuthErrorHelper.getAuthErrorMessage(e));
    } catch (e, stackTrace) {
      // Log the actual exception before converting - this is critical for debugging
      // Unexpected errors (non-FirebaseAuthException) should always be logged as errors
      Log.e(
        'AuthRepository: Unexpected error during OTP verification: ${e.runtimeType}',
        error: e,
        stackTrace: stackTrace,
      );
      onFailure(FirebaseAuthErrorHelper.getAuthErrorMessage(e));
    }
  }
}
