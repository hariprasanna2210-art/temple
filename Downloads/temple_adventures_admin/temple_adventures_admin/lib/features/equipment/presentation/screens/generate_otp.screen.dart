import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/all_equipment.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/equipment_log.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/otp.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/widgets/submit_equipment_item.modal.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../services/logging.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../user/models/user.model.dart';
import '../../model/otp_validation.model.dart';
import '../../widgets/banner_container.dart';
import '../../widgets/equipment_items_summary_table.dart';
import '../../widgets/otp_validtion_stream.dart';

class GenerateOtpScreen extends StatefulWidget {
  const GenerateOtpScreen({super.key});
  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const GenerateOtpScreen());

  @override
  State<GenerateOtpScreen> createState() => _GenerateOtpScreenState();
}

class _GenerateOtpScreenState extends State<GenerateOtpScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllUsersCubit>().fetchAllUsers();
      context.read<OtpCubit>().generateOtp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Generate OTP',
        description: 'Share OTP and verify rented equipment',
      ),
      body: _buildMainContent(),
      bottomNavigationBar: const _ApproveBanner(),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) {
        if (state.firebaseTrackingId == null) {
          return CircularProgressIndicator().center;
        }
        return OtpValidationStream(
          firebaseTrackingId: state.firebaseTrackingId!,
          builder: (validation) {
            return BlocBuilder<AllUsersCubit, AllUsersState>(
              builder: (context, usersState) {
                final renter = _findRenter(usersState.users, validation.renterID.toString());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: Screen.width),
                    Spacing.h24,
                    _OtpDisplay(otp: validation.otp),
                    Spacing.h24,
                    _OtpStatusMessage(validation: validation, renter: renter),
                    if (validation.equipmentItem.isNotEmpty) ...[
                      Spacing.h40,
                      EquipmentItemsSummaryTable(validation.equipmentItem),
                    ],
                  ],
                );
              },
            );
          },
        ).paddingAll(20);
      },
    );
  }

  User? _findRenter(List<User> users, String renterId) {
    return users.firstWhereOrNull((e) => e.id.toString() == renterId);
  }
}

class _OtpStatusMessage extends StatelessWidget {
  final OtpValidation validation;
  final User? renter;

  const _OtpStatusMessage({
    required this.validation,
    required this.renter,
  });

  @override
  Widget build(BuildContext context) {
    if (validation.equipmentItem.isEmpty) {
      return _buildGeneratingMessage();
    } else {
      return _buildSharedMessage(renter);
    }
  }

  Widget _buildGeneratingMessage() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(color: Colors.black, fontFamily: 'Nunito'),
        children: [
          WidgetSpan(
            child: const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ).size(10, 10).paddingOnly(bottom: 5, right: 10),
          ),
          const TextSpan(
            text: 'Share ',
          ),
          const TextSpan(
            text: 'OTP ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: skyBlueColor,
            ),
          ),
          const TextSpan(text: 'to your diver buddy so you can '),
          const TextSpan(
            text: 'verify',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: skyBlueColor,
            ),
          ),
          const TextSpan(text: ' Equipment'),
        ],
      ),
    );
  }

  Widget _buildSharedMessage(User? renter) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(color: Colors.black, fontFamily: 'Nunito'),
        children: [
          const TextSpan(
            text: 'OTP ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: skyBlueColor,
            ),
          ),
          const TextSpan(text: 'shared with '),
          TextSpan(
            text: '${renter?.fullName ?? 'Unknown User'},',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: skyBlueColor,
            ),
          ),
          const TextSpan(text: ' Approve only after verification.'),
        ],
      ),
    );
  }
}

class _OtpDisplay extends StatelessWidget {
  final String otp;

  const _OtpDisplay({required this.otp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xffD1F8FF).withOpacity(0.34),
      ),
      child:
          Text(
            otp,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
          ).center,
    );
  }
}

class _ApproveBanner extends StatelessWidget {
  const _ApproveBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 60,
        width: double.infinity,
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BlocBuilder<OtpCubit, OtpState>(
          builder: (context, state) {
            if (state.firebaseTrackingId == null) {
              return const SizedBox();
            }
            return BannerContainer(
              height: 45,
              child:
                  OtpValidationStream(
                    firebaseTrackingId: state.firebaseTrackingId!,
                    builder: (validation) {
                      return _ApproveButton(validation: validation);
                    },
                  ).center,
            ).center.width(Screen.width);
          },
        ),
      ),
    );
  }
}

class _ApproveButton extends StatelessWidget {
  final OtpValidation validation;

  const _ApproveButton({required this.validation});

  @override
  Widget build(BuildContext context) {
    final isEnabled = validation.equipmentItem.isNotEmpty;

    return BlocSelector<EquipmentLogCubit, EquipmentLogState, bool>(
      selector: (state) => state.status is EquipmentLogLoading,
      builder: (context, isLoading) {
        if (isLoading) {
          return const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ).size(15, 15);
        }

        return InkWell(
          onTap: isEnabled && !isLoading ? () => _onApprovePressed(context, validation) : null,
          child:
              Text(
                'Log & Approve',
                style: TextStyle(
                  color: Colors.white.withOpacity(isEnabled ? 1 : 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ).center,
        );
      },
    );
  }

  Future<void> _onApprovePressed(BuildContext context, OtpValidation validation) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    await SubmitEquipmentItemModal.show(
      context,
      validation.equipmentItem,
      () => _approveRental(rootContext, validation),
    );
  }

  Future<void> _approveRental(BuildContext context, OtpValidation validation) async {
    final equipmentCubit = context.read<EquipmentLogCubit>();
    final otpCubit = context.read<OtpCubit>();
    final usersCubit = context.read<AllUsersCubit>();
    final userCubit = context.read<UserCubit>();
    final allEquipmentCubit = context.read<AllEquipmentCubit>();

    final currentUserId = userCubit.state.currentUser?.id;
    final firebaseTrackingId = otpCubit.state.firebaseTrackingId;

    if (firebaseTrackingId == null) {
      Log.e('firebaseTrackingId is null');
      if (context.mounted) {
        context.showSnackBar('Error: Missing tracking information');
      }
      return;
    }

    if (currentUserId == null) {
      Log.e('currentUserId is null');
      if (context.mounted) {
        context.showSnackBar('Error: Missing approver information');
      }
      return;
    }

    try {
      await equipmentCubit.approveRentalAndAddLog(
        validation: validation,
        approverId: currentUserId.toString(),
        employees: usersCubit.state.users,
        firebaseTrackingId: firebaseTrackingId,
      );

      await allEquipmentCubit.fetchEquipmentItems();

      if (!context.mounted) return;
      Navigator.popUntil(context, (route) => route.settings.name == 'AllEquipmentScreen');
    } catch (e, stack) {
      Log.e('approveRentalAndAddLog failed', error: e, stackTrace: stack);
      if (context.mounted) {
        context.showSnackBar('Failed to approve rental: ${e.toString()}');
      }
    } finally {
      otpCubit.clearFirebaseTrackingId();
    }
  }
}
