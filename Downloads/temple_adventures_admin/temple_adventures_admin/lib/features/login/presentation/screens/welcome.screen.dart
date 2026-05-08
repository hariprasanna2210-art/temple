import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/dashboard/presentation/screens/dashboard.screen.dart';
import 'package:temple_adventures_admin/features/user/enums/roles.enum.dart';
import 'package:temple_adventures_admin/utils/constants.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_image.dart';
import '../../../../widgets/custom_floating_action_button.dart';
import '../../../user/bloc/user.cubit.dart';
import '../../../user/models/user.model.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  static Route route() => MaterialPageRoute(builder: (context) => const WelcomeView());

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  User? get user => context.read<UserCubit>().state.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CustomFloatingActionButton(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(DashboardScreen.route(), (route) => false);
        },
        child: const Icon(Icons.arrow_forward_ios_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppImage(appLogo, height: 100, width: 100),
              Spacing.h20,
              SizedBox(
                width: Screen.width,
                child: Text(
                  'Hi,',
                  style: TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w700),
                ),
              ),
              Spacing.h20,
              Text(
                '${user?.firstName}',
                style: TextStyle(fontSize: 40, color: skyBlueColor, fontWeight: FontWeight.w700),
              ),
              Spacing.h5,
              Text(
                user?.role.label ?? 'Office Staff',
                style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
