import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/all_equipment.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/verify_otp.screen.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_image.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../utils/constants.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../model/equipment_item.model.dart';
import '../../widgets/banner_container.dart';

class EquipmentSummaryScreen extends StatefulWidget {
  const EquipmentSummaryScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const EquipmentSummaryScreen());

  @override
  State<EquipmentSummaryScreen> createState() => _EquipmentSummaryScreenState();
}

class _EquipmentSummaryScreenState extends State<EquipmentSummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Summary',
        description: 'Please verify your selected items',
      ),
      body:
          BlocBuilder<AllEquipmentCubit, AllEquipmentState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacing.h20,
                  ...state.selectedItems.map((item) => _EquipmentCard(item)),
                ],
              );
            },
          ).paddingHorizontal(16).scrollable,
      bottomNavigationBar: _VerifyWithOTPBanner(),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;

  const _EquipmentCard(this.item);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AllEquipmentCubit>();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      width: Screen.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(
            item.photo ?? placeHolderImage,
            height: 70,
            width: 70,
          ),
          Spacing.w16,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.equipmentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.category.name,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xff6B6868).withOpacity(0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              cubit.toggleEquipmentItemSelection(item);
              if (cubit.state.selectedItems.isEmpty) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close),
          ).center.height(70),
        ],
      ).paddingAll(8),
    ).paddingOnly(bottom: 16);
  }
}

class _VerifyWithOTPBanner extends StatelessWidget {
  const _VerifyWithOTPBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllEquipmentCubit, AllEquipmentState>(
      builder: (context, state) {
        if (state.selectedItems.isEmpty) return const SizedBox();

        return SafeArea(
          child: Container(
            height: 60,
            width: double.infinity,
            color: Colors.transparent,
            child: BannerContainer(
              height: 45,
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${state.selectedItems.length} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: const [
                        TextSpan(
                          text: ' Equipment selected',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, VerifyOTPScreen.route());
                    },
                    child: Text(
                      'Verify with OTP',
                      style: TextStyle(
                        color: skyBlueColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).paddingHorizontal(16),
            ).center.width(Screen.width),
          ),
        );
      },
    );
  }
}
