import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/all_equipment.cubit.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../user/models/user.model.dart';
import '../../bloc/otp.cubit.dart';
import '../../model/equipment_item.model.dart';
import '../../model/otp_validation.model.dart';
import '../../widgets/banner_container.dart';
import '../../widgets/equipment_items_summary_table.dart';
import '../../widgets/otp_validtion_stream.dart';

final _defaultPinTheme = PinTheme(
  width: 56,
  height: 56,

  textStyle: const TextStyle(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
  decoration: BoxDecoration(
    border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
    borderRadius: BorderRadius.circular(20),
  ),
);

final _focusedPinTheme = _defaultPinTheme.copyDecorationWith(
  border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
  borderRadius: BorderRadius.circular(8),
);

final _submittedPinTheme = _defaultPinTheme.copyWith(
  decoration: _defaultPinTheme.decoration?.copyWith(
    color: const Color.fromRGBO(234, 239, 243, 1),
  ),
);

class VerifyOTPScreen extends StatefulWidget {
  const VerifyOTPScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const VerifyOTPScreen());

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllUsersCubit>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Verify OTP',
          description: 'Ask any diver to generate Equipment OTP',
          hideBackButton: true,
        ),
        body: _buildMainContent(),
        bottomNavigationBar: _VerifyWithOTPBanner(),
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocSelector<AllEquipmentCubit, AllEquipmentState, List<EquipmentItem>>(
              selector: (state) => state.selectedItems,
              builder: (context, selectedItems) {
                return EquipmentItemsSummaryTable(selectedItems);
              },
            ),
            Spacing.h36,
            _buildInstructionText(),
            Spacing.h48,
            _buildOtpInput(state),
            if (state.status is OtpError)
              EmptyStateMessage(
                message: 'error occured',
              ),
            if (state.firebaseTrackingId != null) _buildVerificationStream(state.firebaseTrackingId!),
          ],
        ).paddingAll(20);
      },
    );
  }

  Widget _buildInstructionText() {
    return RichText(
      text: TextSpan(
        text: 'Above information needs to be verified by any ',
        style: TextStyle(color: Colors.black, fontFamily: 'Nunito'),
        children: const <TextSpan>[
          TextSpan(text: 'Diver', style: TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor)),
          TextSpan(text: ', ask your diver buddy to share '),
          TextSpan(text: 'OTP', style: TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor)),
          TextSpan(text: ' and start the verification process in their app.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOtpInput(OtpState state) {
    return Pinput(
      onCompleted: (pin) => context.read<OtpCubit>().verifyOTP(pin),
      onChanged: (pin) => context.read<OtpCubit>().onOtpChange(pin),
      focusedPinTheme: _focusedPinTheme,
      submittedPinTheme: _submittedPinTheme,
      keyboardType: const TextInputType.numberWithOptions(),
    );
  }

  Widget _buildVerificationStream(String firebaseTrackingId) {
    return OtpValidationStream(
      firebaseTrackingId: firebaseTrackingId,
      builder: (validation) {
        return BlocBuilder<AllUsersCubit, AllUsersState>(
          builder: (context, usersState) {
            final employee = _findEmployee(usersState.users, validation.approverID);
            return _VerificationText(
              validation: validation,
              employee: employee,
            );
          },
        );
      },
    );
  }

  User? _findEmployee(List<User> users, String? approverId) {
    if (approverId == null) return null;
    return users.firstWhereOrNull((u) => u.id.toString() == approverId);
  }
}

class _VerificationText extends StatelessWidget {
  final OtpValidation validation;
  final User? employee;

  const _VerificationText({required this.validation, this.employee});

  @override
  Widget build(BuildContext context) {
    if (validation.approve == true) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
          children: [
            WidgetSpan(
              child: const Icon(
                Icons.verified,
                color: Colors.green,
              ).paddingOnly(right: 10),
            ),
            const TextSpan(
              text: 'Equipment is verified by ',
            ),
            TextSpan(
              text: '${employee?.fullName ?? validation.approverID} ',
              style: const TextStyle(
                color: skyBlueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ).paddingOnly(top: 33);
    }

    return RichText(
      text: TextSpan(
        text: '${employee?.fullName ?? validation.approverID} ',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: skyBlueColor, fontFamily: 'Nunito'),
        children: const <TextSpan>[
          TextSpan(
            text: 'is verifying your Equipment',
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ).paddingOnly(top: 33);
  }
}

class _VerifyWithOTPBanner extends StatelessWidget {
  const _VerifyWithOTPBanner();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).viewInsets.bottom != 0) {
      return const SizedBox();
    }

    return SafeArea(
      child: Container(
        height: 60,
        width: double.infinity,
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BlocBuilder<OtpCubit, OtpState>(
          builder: (context, state) {
            return BannerContainer(
              height: 45,
              child: _BannerContent(state: state),
            ).center.width(Screen.width);
          },
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final OtpState state;

  const _BannerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.firebaseTrackingId == null) {
      return _VerifyButton(state: state);
    } else {
      return _VerificationStatusStream(firebaseTrackingId: state.firebaseTrackingId!);
    }
  }
}

class _VerifyButton extends StatelessWidget {
  final OtpState state;

  const _VerifyButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isEnabled = state.otp?.length == 4;

    return InkWell(
      onTap: isEnabled ? () => context.read<OtpCubit>().verifyOTP(state.otp!) : null,
      child:
          Text(
            'Verify OTP',
            style: TextStyle(
              color: Colors.white.withOpacity(isEnabled ? 1 : 0.5),
              fontWeight: FontWeight.bold,
            ),
          ).center,
    );
  }
}

class _VerificationStatusStream extends StatelessWidget {
  final String firebaseTrackingId;

  const _VerificationStatusStream({required this.firebaseTrackingId});

  @override
  Widget build(BuildContext context) {
    return OtpValidationStream(
      firebaseTrackingId: firebaseTrackingId,
      builder: (validation) {
        if (validation.approve == true) {
          final allEquipmentCubit = context.read<AllEquipmentCubit>();

          return InkWell(
            onTap: () async {
              allEquipmentCubit.resetEquipmentItemSelection();
              await allEquipmentCubit.fetchEquipmentItems();
              if (!context.mounted) return;
              Navigator.popUntil(context, (route) => route.settings.name == 'AllEquipmentScreen');
            },
            child:
                const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).center,
          );
        } else {
          return const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ).size(15, 15);
        }
      },
    ).center;
  }
}
