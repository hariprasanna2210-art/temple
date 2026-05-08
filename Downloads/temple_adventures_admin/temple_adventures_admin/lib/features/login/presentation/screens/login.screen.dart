import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:temple_adventures_admin/features/login/presentation/screens/welcome.screen.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import '../../../../blocs/auth.cubit.dart';
import '../../../../repository/auth.repository.dart';
import '../../../../theme.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/locator.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_image.dart';
import '../../../../widgets/phone_number.dart';
import '../../../user/repository/user.repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (context) => AuthCubit(
        userRepository: locator<UserRepository>(),
        authRepository: locator<AuthRepository>(),
        logRepository: locator<LogsRepository>(),
      ),
      child: const LoginScreen(),
    ),
    settings: const RouteSettings(name: 'LoginScreen'),
  );

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with CodeAutoFill {
  static const int _otpLength = 6;

  late TextEditingController _phoneNumberTED;
  late TextEditingController _otpController;
  String? _countryCode;
  final _formKey = GlobalKey<FormState>();
  bool _isAutoFilling = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberTED = TextEditingController();
    _otpController = TextEditingController();
    listenForCode();
  }

  @override
  void dispose() {
    _phoneNumberTED.dispose();
    _otpController.dispose();
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) => _handleAuthStateChange(context, state),
      builder: (context, state) {
        final bool showOtpField = state is AuthOtpCodeSent || state is AuthOtpTimeout || state is AuthVerifyingOtp;
        final bool showResendButton = state is AuthOtpTimeout;
        final bool isLoading = state is AuthCheckingUser || state is AuthSendingOtp || state is AuthVerifyingOtp;
        final int? remainingSeconds = state is AuthOtpCodeSent ? state.remainingSeconds : null;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacing.h30,
                const Text(
                  'Howdy,',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ).left,
                Spacing.h20,
                AppImage(appLogo).size(150, 150),
                Spacing.h20,
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'On behalf of the whole department, welcome ',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      TextSpan(
                        text: 'aboard.',
                        style: const TextStyle(fontSize: 20, color: skyBlueColor),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacing.h30,
                if (state is! AuthLoginSuccess)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PhoneNumberInput(
                          controller: _phoneNumberTED,
                          required: true,
                          validator: _validatePhoneNumber,
                          onChanged: (PhoneNumber phone) {
                            _countryCode = phone.countryCode;
                          },
                          onCountryChanged: (country) {
                            _countryCode = country.dialCode;
                          },
                        ),
                        if (showOtpField) ...[
                          Spacing.h10,
                          AppTextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            labelText: 'Enter OTP',
                            validator: (value) {
                              if (showOtpField && !showResendButton) {
                                if (value == null || value.isEmpty) {
                                  return 'OTP is required';
                                } else if (value.length != _otpLength) {
                                  return 'OTP must be $_otpLength digits';
                                }
                              }
                              return null;
                            },
                            onChanged: (code) {
                              // Skip auto-verification if SMS autofill is setting the value
                              if (_isAutoFilling) return;
                              
                              if (code.length == _otpLength) {
                                FocusScope.of(context).unfocus();
                                context.read<AuthCubit>().verifyOtp(context, code);
                              }
                            },
                          ),
                          if (remainingSeconds != null && remainingSeconds > 0) ...[
                            Spacing.h10,
                            Text(
                              'OTP expires in ${remainingSeconds}s',
                              style: const TextStyle(
                                color: skyBlueColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          Spacing.h80,
                        ],
                      ],
                    ),
                  ),
              ],
            ).scrollable.paddingHorizontal(20),
          ),
          bottomNavigationBar: AppButton.flat(
            text: showOtpField ? (showResendButton ? 'Resend OTP' : 'Verify OTP') : 'Proceed',
            showLoading: isLoading,
            onTap: () async {
              final authCubit = context.read<AuthCubit>();

              if (showResendButton) {
                await authCubit.resendOtp();
                return;
              }

              if (_formKey.currentState?.validate() != true) {
                return;
              }

              if (showOtpField && _otpController.text.length == _otpLength) {
                await authCubit.verifyOtp(context, _otpController.text);
                return;
              }

              if (!isLoading) {
                context.closeKeyboard();
                await authCubit.isUserExists(
                  countryCode: _countryCode!,
                  phoneNumber: _phoneNumberTED.text,
                );
              }
            },
          ).paddingAll(20),
        );
      },
    );
  }

  /// Validate phone number
  String? _validatePhoneNumber(PhoneNumber? phone) {
    try {
      if (phone != null && phone.isValidNumber()) {
        return null;
      } else {
        return 'Please enter a valid mobile number';
      }
    } catch (_) {
      return 'Invalid mobile number';
    }
  }

  /// Called when SMS auto-fill receives a new code
  @override
  void codeUpdated() {
    if (!mounted) return;

    _isAutoFilling = true; // Set flag before setting text
    setState(() {
      _otpController.text = code ?? '';
    });

    // Add small delay to let user see the OTP before auto-verifying
    // Also prevents onChanged from triggering duplicate verification
    Future.delayed(const Duration(milliseconds: 500), () {
      _isAutoFilling = false; // Reset flag after delay
      if (_otpController.text.length == _otpLength && mounted) {
        context.read<AuthCubit>().verifyOtp(context, _otpController.text);
      }
    });
  }

  /// Handle authentication state changes
  Future<void> _handleAuthStateChange(BuildContext context, AuthState state) async {
    if (state is AuthLoginSuccess) {
      _navigateToWelcome(context);
      return;
    }

    if (state is AuthFailure) {
      _showErrorSnackbar(context, state.message);
      return;
    }

    if (state is AuthOtpCodeSent && state.errorMessage != null) {
      _showErrorSnackbar(context, state.errorMessage!);
      return;
    }

    if (state is AuthUserCheckSuccess) {
      await context.read<AuthCubit>().signInWithPhoneNumber('${_countryCode!}${_phoneNumberTED.text}');
    }
  }

  /// Navigate to welcome screen
  void _navigateToWelcome(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        WelcomeView.route(),
        (route) => false,
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      context.showSnackBar(message);
    }
  }
}
