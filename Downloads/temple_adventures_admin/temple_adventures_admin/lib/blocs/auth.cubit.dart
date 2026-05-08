import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../features/logs/enums/action_type.enum.dart';
import '../features/user/bloc/user.cubit.dart';
import '../features/user/repository/user.repository.dart';
import '../repository/auth.repository.dart';
import '../services/logging.dart';
import '../services/shared_preference_service.dart';
import '../utils/firebase_auth_error_helper.dart';
import '../utils/supabase_error_helper.dart';

part 'auth.cubit.freezed.dart';

/// Mixin for safely emitting states.
/// Prevents errors when trying to emit after the cubit is closed.
mixin SafeEmitMixin<S> on Cubit<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}

/// Cubit for managing authentication state and flow.
/// 
/// Handles the complete phone number-based OTP authentication process:
/// 1. User existence check
/// 2. OTP request and sending
/// 3. Manual OTP verification
/// 4. Session management
class AuthCubit extends Cubit<AuthState> with SafeEmitMixin<AuthState> {
  // OTP validity duration (60 seconds)
  static const Duration _otpValidityDuration = Duration(seconds: 60);
  // Timeout for OTP request (45 seconds) - prevents infinite loading
  static const Duration _otpRequestTimeout = Duration(seconds: 45);

  String? _verificationId;
  String? _completePhoneNumber;
  int? _userId;
  Timer? _otpTimer;
  Timer? _timeoutTimer;
  int? _currentRemainingSeconds;
  bool _isVerifyingOtp = false;

  final UserRepository userRepository;
  final AuthRepository authRepository;
  final LogsRepository logRepository;

  AuthCubit({
    required this.userRepository,
    required this.authRepository,
    required this.logRepository,
  }) : super(const AuthState.initial());

  @override
  Future<void> close() {
    _otpTimer?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }

  /// Check if user exists in the system
  Future<void> isUserExists({
    required String countryCode,
    required String phoneNumber,
  }) async {
    safeEmit(const AuthState.checkingUser());
    try {
      _userId = await userRepository.isUserExists(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );

      if (_userId == null) {
        safeEmit(AuthState.failure(FirebaseAuthErrorHelper.errorUserNotAuthorized));
        return;
      }

      Log.i('User $_userId verified successfully.');
      safeEmit(AuthState.userCheckSuccess(_userId));
    } catch (e, stack) {
      Log.e('Failed to verify user: $e', error: e, stackTrace: stack);

      if (SupabaseErrorHelper.isConfigurationError(e)) {
        final errorMessage = SupabaseErrorHelper.getSupabaseErrorMessage(e);
        safeEmit(AuthState.failure(errorMessage));
        SentryHelper.captureException(
          e,
          stackTrace: stack,
          extra: {
            'error_code': SupabaseErrorHelper.getErrorCode(e),
            'phone_number': phoneNumber,
            'country_code': countryCode,
            'error_type': 'supabase_configuration_error',
            'operation': 'isUserExists',
          },
          tag: 'supabase_auth',
        );
      } else {
        safeEmit(AuthState.failure(FirebaseAuthErrorHelper.errorUserNotAuthorized));
      }
    }
  }

  /// Requests OTP for phone number authentication.
  /// 
  /// **Flow:**
  /// 1. Sets up a timeout to prevent infinite loading (45 seconds)
  /// 2. Calls Firebase to send OTP
  /// 3. Handles different callbacks:
  ///    - `onCodeSent`: OTP sent successfully (user must enter manually)
  ///    - `onTimeout`: SMS autofill timed out (user must enter manually)
  ///    - `onFailure`: Error occurred
  /// **Note:** Users must manually enter the OTP code.
  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    _completePhoneNumber = phoneNumber;
    
    // Reset all state for new OTP request
    _verificationId = null;
    _isVerifyingOtp = false;
    _otpTimer?.cancel();
    _timeoutTimer?.cancel();
    
    Log.i('Requesting OTP for phone number: $phoneNumber');
    safeEmit(const AuthState.sendingOtp());

    // Set up timeout to prevent infinite loading if Firebase doesn't respond
    _timeoutTimer = Timer(_otpRequestTimeout, () {
      if (!isClosed) {
        Log.w('OTP request timeout - no callback received for $phoneNumber');
        safeEmit(
          AuthState.failure(
            'OTP request is taking longer than expected. Please check your network connection and try again.',
          ),
        );
      }
    });

    try {
      await authRepository.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _timeoutTimer?.cancel();
          _verificationId = verificationId;
          Log.i('OTP sent to $phoneNumber. Verification ID: $verificationId');
          _startOtpTimer();
          safeEmit(AuthState.otpCodeSent(verificationId));
        },
        onTimeout: (verificationId) {
          _timeoutTimer?.cancel();
          _verificationId = verificationId;
          Log.w('OTP timeout for $phoneNumber. Verification ID: $verificationId');
          safeEmit(AuthState.otpTimeout(verificationId));
        },
        onFailure: (error) {
          _timeoutTimer?.cancel();
          Log.e('OTP sending failed for $phoneNumber: $error', error: error);
          safeEmit(AuthState.failure(FirebaseAuthErrorHelper.getAuthErrorMessage(error)));
        },
        onSuccess: () {
          // Legacy callback - not used when onCodeSent is called
          // Kept for backward compatibility with repository interface
          _timeoutTimer?.cancel();
        },
      );
    } catch (e, stack) {
      _timeoutTimer?.cancel();
      Log.e('Exception during OTP request for $phoneNumber: $e', error: e, stackTrace: stack);
      safeEmit(AuthState.failure(FirebaseAuthErrorHelper.getAuthErrorMessage(e)));
    }
  }

  /// Resends OTP to the same phone number.
  /// 
  /// Resets the verification ID and OTP timer, then requests a new OTP.
  Future<void> resendOtp() async {
    if (_completePhoneNumber == null) {
      safeEmit(AuthState.failure(FirebaseAuthErrorHelper.errorPhoneNumberMissing));
      return;
    }
    _otpTimer?.cancel();
    _verificationId = null;
    await signInWithPhoneNumber(_completePhoneNumber!);
  }

  /// Verifies the OTP entered by the user.
  /// 
  /// **Preconditions:**
  /// - Verification ID must be set (OTP must have been sent)
  /// - User ID must be set (user must have passed existence check)
  /// - OTP must be exactly 6 digits
  /// - No verification already in progress (prevents duplicate requests)
  /// 
  /// **Flow:**
  /// 1. Validate preconditions
  /// 2. Call repository to verify OTP with Firebase
  /// 3. On success: Save user ID, fetch user data, log login, emit success
  /// 4. On failure: Differentiate between user input errors and system errors
  Future<void> verifyOtp(BuildContext context, String otp) async {
    // Prevent duplicate verification attempts
    if (_isVerifyingOtp) {
      Log.w('OTP verification already in progress, ignoring duplicate request');
      return;
    }

    if (_verificationId == null || _verificationId!.isEmpty) {
      safeEmit(AuthState.failure(FirebaseAuthErrorHelper.errorVerificationIdMissing));
      return;
    }
    if (_userId == null) {
      safeEmit(AuthState.failure(FirebaseAuthErrorHelper.errorUserNotVerified));
      return;
    }

    if (otp.isEmpty || otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      safeEmit(AuthState.failure('Please enter a valid 6-digit OTP.'));
      return;
    }

    _isVerifyingOtp = true;
    safeEmit(const AuthState.verifyingOtp());

    try {
      await authRepository.verifyOtp(
        verificationId: _verificationId!,
        otp: otp,
        onSuccess: () async {
          _isVerifyingOtp = false;
          _otpTimer?.cancel();
          await SharedPrefKeys.userId.setInt(_userId!);
          if (context.mounted) {
            await context.read<UserCubit>().getUserData(_userId!);
          }
          await _logSuccessfulLogin();
          safeEmit(const AuthState.success());
        },
        onFailure: (error) {
          _isVerifyingOtp = false;
          
          final isUserInputError =
              error.contains('invalid-verification-code') ||
              error.contains('invalid-verification-id') ||
              error.contains('session-expired') ||
              error.contains('incorrect') ||
              error.contains('The OTP you entered is incorrect');

          if (isUserInputError) {
            Log.w('OTP verification failed: User entered incorrect OTP');
          } else {
            Log.e('OTP verification failed: $error', error: error);
            SentryHelper.captureException(
              Exception('OTP verification failed: $error'),
              extra: {
                'error_type': error.runtimeType.toString(),
                'error_string': error,
                'verification_id': _verificationId?.substring(0, 10) ?? 'null',
                'phone_number': _completePhoneNumber?.substring(0, 5) ?? 'null',
                'user_id': _userId,
                'remaining_seconds': _currentRemainingSeconds,
                'has_verification_id': _verificationId != null && _verificationId!.isNotEmpty,
              },
              tag: 'otp_verification',
            );
          }

          final message = FirebaseAuthErrorHelper.getAuthErrorMessage(error);
          if (_verificationId != null && _verificationId!.isNotEmpty) {
            safeEmit(
              AuthState.otpCodeSent(
                _verificationId!,
                remainingSeconds: _currentRemainingSeconds,
                errorMessage: message,
              ),
            );
          } else {
            safeEmit(AuthState.failure(message));
          }
        },
      );
    } catch (e, stack) {
      _isVerifyingOtp = false;
      Log.e('Exception during OTP verification', error: e, stackTrace: stack);
      final message = FirebaseAuthErrorHelper.getAuthErrorMessage(e);
      if (_verificationId != null && _verificationId!.isNotEmpty) {
        safeEmit(
          AuthState.otpCodeSent(
            _verificationId!,
            remainingSeconds: _currentRemainingSeconds,
            errorMessage: message,
          ),
        );
      } else {
        safeEmit(AuthState.failure(message));
      }
    }
  }

  /// Start OTP validity countdown timer
  void _startOtpTimer() {
    _otpTimer?.cancel();
    int remainingSeconds = _otpValidityDuration.inSeconds;
    _currentRemainingSeconds = remainingSeconds;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      _currentRemainingSeconds = remainingSeconds;

      if (remainingSeconds > 0) {
        final currentState = state;
        if (currentState is AuthOtpCodeSent) {
          safeEmit(
            AuthState.otpCodeSent(
              currentState.verificationId,
              remainingSeconds: remainingSeconds,
            ),
          );
        }
      } else {
        timer.cancel();
        _currentRemainingSeconds = null;
        if (_verificationId != null) {
          safeEmit(AuthState.otpTimeout(_verificationId!));
        }
      }
    });
  }

  /// Log successful login action
  Future<void> _logSuccessfulLogin() async {
    await logRepository.addLog(
      actionType: ActionType.signedIn,
      referenceId: _userId,
      additionalInformation: {
        'phone': _completePhoneNumber,
      },
    );
    Log.i('User $_userId logged in successfully with phone $_completePhoneNumber.');
  }
}

/// AUTH STATES
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.checkingUser() = AuthCheckingUser;
  const factory AuthState.userCheckSuccess(int? userId) = AuthUserCheckSuccess;
  const factory AuthState.sendingOtp() = AuthSendingOtp;
  const factory AuthState.otpCodeSent(String verificationId, {int? remainingSeconds, String? errorMessage}) =
      AuthOtpCodeSent;
  const factory AuthState.otpTimeout(String verificationId) = AuthOtpTimeout;
  const factory AuthState.verifyingOtp() = AuthVerifyingOtp;
  const factory AuthState.success() = AuthLoginSuccess;
  const factory AuthState.failure(String message, {String? phone}) = AuthFailure;
}
