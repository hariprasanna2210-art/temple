import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/equipment_log.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/widgets/submit_equipment_item.modal.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../bloc/all_equipment.cubit.dart';
import '../../model/enriched_equipment_logs.model.dart';
import '../../widgets/banner_container.dart';
import '../../widgets/equipment_items_summary_table.dart';

class EquipmentLogDetailsScreen extends StatefulWidget {
  final EnrichedEquipmentLogs log;

  const EquipmentLogDetailsScreen({super.key, required this.log});

  static MaterialPageRoute<dynamic> route(EnrichedEquipmentLogs log) => MaterialPageRoute(
    builder:
        (_) => EquipmentLogDetailsScreen(
          log: log,
        ),
  );

  @override
  State<EquipmentLogDetailsScreen> createState() => _EquipmentLogDetailsScreenState();
}

class _EquipmentLogDetailsScreenState extends State<EquipmentLogDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      context.read<AllEquipmentCubit>().fetchEquipmentItems();
      context.read<AllEquipmentCubit>().fetchCategories();
      context.read<EquipmentLogCubit>().fetchEquipmentLogs();
      context.read<AllUsersCubit>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EquipmentLogCubit, EquipmentLogState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Log #${widget.log.logId}',
            description:
                'Equipment log for ${widget.log.equipmentItems.length} item${widget.log.equipmentItems.length == 1 ? '' : 's'}',
          ),
          body: () {
            if (state.status is EquipmentLogLoading) {
              return LoadingOverlay();
            }
            if (state.status is EquipmentLogError) {
              return EmptyStateMessage(
                message: (state.status as EquipmentLogError).message,
              ).center;
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.h32,
                _LogDetails(widget.log),
                Spacing.h32,
                EquipmentItemsSummaryTable(widget.log.equipmentItems),
                _SubmissionInfoText(widget.log),
                Spacing.h60,
              ],
            ).paddingHorizontal(16);
          }(),
          bottomNavigationBar: _SubmissionButton(widget.log),
        );
      },
    );
  }
}

class _LogDetails extends StatelessWidget {
  final EnrichedEquipmentLogs log;

  const _LogDetails(
    this.log,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemDetails('Renter', log.renterName).paddingOnly(bottom: 8),
        _ItemDetails('Approved by', log.approverName).paddingOnly(bottom: 8),
        if (log.collectorPersonId != null && log.collectorName != null)
          _ItemDetails('Collected by', '${log.collectorName}').paddingOnly(bottom: 8),
        _ItemDetails('Rented time', DateFormat('MMM dd, yyyy hh:mm a').format(log.rentedTime)).paddingOnly(bottom: 8),
        if (log.collectedTime != null)
          _ItemDetails(
            'Collection time',
            DateFormat('MMM dd, yyyy hh:mm a').format(log.collectedTime ?? DateTime.now()),
          ).paddingOnly(bottom: 8),
      ],
    ).paddingOnly(left: 15);
  }
}

class _SubmissionButton extends StatelessWidget {
  final EnrichedEquipmentLogs log;
  const _SubmissionButton(this.log);

  @override
  Widget build(BuildContext context) {
    if (log.collectorPersonId != null) return const SizedBox();
    if (log.renterPersonId.toString() == context.read<UserCubit>().state.currentUser?.id.toString()) {
      return const SizedBox();
    }

    return SafeArea(
      child: Container(
        height: 60,
        width: double.infinity,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BannerContainer(
          height: 45,
          child: InkWell(
            onTap: () async {
              final equipmentLogCubit = context.read<EquipmentLogCubit>();
              final currentUser = context.read<UserCubit>().state.currentUser;
              if (currentUser == null) return;

              await SubmitEquipmentItemModal.show(
                context,
                log.equipmentItems,
                () async {
                  await equipmentLogCubit.completeSubmission(log, currentUser);
                },
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: Center(
              child: Text(
                'Start submission',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemDetails extends StatelessWidget {
  final String title;
  final String value;

  const _ItemDetails(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$title : ',
        style: const TextStyle(
          fontFamily: 'Nunito',
          color: Colors.black,
          fontSize: 14,
        ),
        children: <TextSpan>[
          TextSpan(
            text: ' $value',
            style: const TextStyle(color: Color(0xff727272)),
          ),
        ],
      ),
    );
  }
}

class _SubmissionInfoText extends StatelessWidget {
  final EnrichedEquipmentLogs log;

  const _SubmissionInfoText(this.log);

  @override
  Widget build(BuildContext context) {
    if (log.collectorPersonId != null) return const SizedBox();

    if (log.renterPersonId.toString() == context.read<UserCubit>().state.currentUser?.id.toString()) {
      return Expanded(
        child:
            RichText(
              text: TextSpan(
                text: 'In order to complete ',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.black,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: ' Submission',
                    style: TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor),
                  ),
                  const TextSpan(
                    text: ', ask you diver buddy to verify each item in there app. Share the ID # ',
                  ),
                  TextSpan(
                    text: log.logId.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor),
                  ),
                  const TextSpan(
                    text: ' to find the log easily.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ).center,
      );
    }

    return Expanded(
      child:
          RichText(
            text: const TextSpan(
              text: 'Please review each item to ensure it is in working condition. Once verified, click the "',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.black,
                fontSize: 14,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'Start Submission',
                  style: TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor),
                ),
                TextSpan(
                  text: '" button. Then, go through each item and click "',
                ),
                TextSpan(
                  text: 'Accept Submission',
                  style: TextStyle(fontWeight: FontWeight.bold, color: skyBlueColor),
                ),
                TextSpan(
                  text: '" to confirm.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ).center,
    );
  }
}
