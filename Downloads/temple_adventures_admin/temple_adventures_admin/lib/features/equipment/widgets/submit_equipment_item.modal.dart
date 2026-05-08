import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/all_equipment.cubit.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../utils/styling/app_measurements.dart';
import '../../../utils/styling/spacing_widgets.dart';
import '../model/equipment_item.model.dart';
import 'banner_container.dart';

class SubmitEquipmentItemModal extends StatefulWidget {
  final List<EquipmentItem> items;
  final Function onSuccess;

  const SubmitEquipmentItemModal({
    super.key,
    required this.items,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context,
    List<EquipmentItem> items,
    Function onSuccess,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return SubmitEquipmentItemModal(
          items: items,
          onSuccess: onSuccess,
        );
      },
    );
  }

  @override
  State<SubmitEquipmentItemModal> createState() => _SubmitEquipmentItemModalState();
}

class _SubmitEquipmentItemModalState extends State<SubmitEquipmentItemModal> {
  List<String> verifiedIds = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllEquipmentCubit, AllEquipmentState>(
      builder: (context, state) {
        final isLoading = state.status is AllEquipmentLoading;
        return SafeArea(
          top: false,
          child: Container(
            height: Screen.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            width: Screen.width,
            child: Column(
              children: [
                Spacing.h10,
                Row(
                  children: [
                    const Text(
                      'Verify equipment',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ).paddingHorizontal(16),
                const Divider(height: 1, color: Colors.grey).paddingHorizontal(8),
                Spacing.h12,

                ...(widget.items).map(
                  (item) {
                    bool isVerified = verifiedIds.contains(item.id.toString());

                    return InkWell(
                      onTap: () {
                        if (isVerified) {
                          verifiedIds.remove(item.id.toString());
                        } else {
                          verifiedIds.add(item.id.toString());
                        }
                        setState(() {});
                      },
                      child: _EquipmentItemTile(item, isVerified),
                    ).paddingOnly(bottom: 12);
                  },
                ),

                const Spacer(),

                BannerContainer(
                  height: 45,
                  child: InkWell(
                    onTap: () {
                      if (isLoading) return;
                      final enable = verifiedIds.length == widget.items.length && widget.items.isNotEmpty;
                      if (!enable) return;
                      Navigator.pop(context);
                      widget.onSuccess();
                    },
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ).size(15, 15).center
                            : Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                  verifiedIds.length == widget.items.length ? 1 : 0.5,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ).center,
                  ),
                ).center.width(Screen.width),

                Spacing.h30,
              ],
            ),
          ).paddingOnly(bottom: MediaQuery.of(context).viewInsets.bottom),
        );
      },
    );
  }
}

class _EquipmentItemTile extends StatelessWidget {
  final EquipmentItem item;
  final bool isVerified;

  const _EquipmentItemTile(this.item, this.isVerified);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isVerified ? Colors.green.withOpacity(0.1) : Colors.red.shade200.withOpacity(0.1),
      ),
      width: Screen.width,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.equipmentName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacing.h4,
              Text(
                isVerified ? 'Verified' : 'Not yet verified',
                style: TextStyle(
                  fontSize: 12,
                  color: isVerified ? Colors.green : Colors.red,
                  fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            isVerified ? Icons.verified : Icons.cancel,
            color: isVerified ? Colors.green : Colors.red,
          ),
        ],
      ).paddingSymmetric(vertical: 8, horizontal: 16),
    ).paddingHorizontal(16);
  }
}
