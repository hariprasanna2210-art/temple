import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:temple_adventures_admin/features/dashboard/presentation/screens/dashboard.screen.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/ota_service.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_image.dart';
import '../../../login/presentation/screens/login.screen.dart';
import '../../../user/bloc/user.cubit.dart';
import '../../bloc/auto_update.cubit.dart';

const progressTextStyle = TextStyle(fontFamily: nunitoBold, color: grey);
const grey = Color(0xff9A9A9A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (_) => const SplashScreen(),
    settings: const RouteSettings(name: 'SplashScreen'),
  );

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Screen.setScreenOrientation();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              AutoUpdateCubit(otaService: OTAService(ShorebirdUpdater()), userCubit: context.read<UserCubit>())
                ..fetchVersionData(),
      child: BlocListener<AutoUpdateCubit, AutoUpdateState>(
        listener: (context, state) {
          if (state is AutoUpdateNavigateToLoginScreen) {
            Navigator.pushReplacement(context, LoginScreen.route());
            return;
          }
          if (state is AutoUpdateNavigateToDashboard) {
            Navigator.pushReplacement(context, DashboardScreen.route());
            return;
          }
          if (state is AutoUpdateError) {
            context.showSnackBar(state.message);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<AutoUpdateCubit, AutoUpdateState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    AppImage(appLogo).size(150, 150).center,
                    Positioned(
                      bottom: 80,
                      width: Screen.width,
                      child: BlocBuilder<AutoUpdateCubit, AutoUpdateState>(
                        builder: (context, state) {
                          if (state is AutoUpdateLoading) {
                            return const _LoadingIndicator();
                          }
                          if (state is AutoUpdateUpdateRequired) {
                            return _UpdatePrompt(state: state);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Checking for updates',
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        Spacing.w10,
        const CircularProgressIndicator(
          strokeWidth: 2,
        ).size(15, 15),
      ],
    ).paddingOnly(bottom: 88);
  }
}

class _UpdatePrompt extends StatefulWidget {
  const _UpdatePrompt({required this.state});

  final AutoUpdateUpdateRequired state;

  @override
  State<_UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<_UpdatePrompt> {
  late AutoUpdateUpdateRequired state;

  @override
  void initState() {
    super.initState();
    state = widget.state;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'There is an update available to ',
            style: progressTextStyle,
            children: <TextSpan>[
              TextSpan(
                text: (Platform.isAndroid) ? state.info.androidVersionNumber : state.info.iosVersionNumber,
                style: const TextStyle(color: skyBlueColor),
              ),
              if (state.info.criticalUpdate == false) ...[
                const TextSpan(text: '.\n Please '),
                TextSpan(
                  text: 'click here',
                  style: const TextStyle(
                    color: skyBlueColor,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () => _navigateToLoginScreen(),
                ),
                const TextSpan(text: ' to skip the current update.'),
              ],
            ],
          ),
        ),
        Spacing.h20,
        AppButton.flat(
          onTap:
              () => _openStore(
                state.info.appStoreLink,
                state.info.playStoreLink,
              ),
          text: 'Update',
          width: 200,
          height: 40,
        ),
      ],
    );
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(context, LoginScreen.route());
  }

  void _openStore(String appStoreLink, String playStoreLink) async {
    final url = Platform.isAndroid ? playStoreLink : appStoreLink;

    if (url.isEmpty) {
      debugPrint('Empty URL');
      return;
    }

    final parsedUri = Uri.tryParse(url);
    if (parsedUri == null || !(parsedUri.hasScheme && parsedUri.hasAuthority)) {
      debugPrint('Invalid URL: $url');
      return;
    }

    if (await canLaunchUrl(parsedUri)) {
      await launchUrl(parsedUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch URL: $url');
    }
  }
}
