import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/equipment/model/equipment_item.model.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../utils/styling/spacing_widgets.dart';

class EquipmentItemsSummaryTable extends StatelessWidget {
  final List<EquipmentItem> selectedPieces;

  const EquipmentItemsSummaryTable(
    this.selectedPieces, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final equipmentMap = <int, List<EquipmentItem>>{};
    for (var item in selectedPieces) {
      equipmentMap.putIfAbsent(item.id!, () => []).add(item);
    }

    return Column(
      children: [
        Text(
          'Equipment details :',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ).paddingOnly(left: 13).left,
        Spacing.h8,
        for (var entry in equipmentMap.entries)
          _ListItem(
            index: equipmentMap.keys.toList().indexOf(entry.key),
            equipmentID: entry.key,
            items: entry.value,
          ),
        Spacing.h8,
        const _DashedLine(),
        Row(
          children: [
            Spacing.w16,
            Text('Total Equipment').paddingVertical(16),
            const Spacer(),
            Text('${selectedPieces.length}').paddingVertical(16),
            Spacing.w16,
          ],
        ),
        const _DashedLine(),
      ],
    );
  }
}

class _ListItem extends StatelessWidget {
  final int equipmentID;
  final List<EquipmentItem> items;
  final int index;

  const _ListItem({
    required this.equipmentID,
    required this.items,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final name = items.first.equipmentName;

    return Row(
      children: [
        Spacing.w16,
        Text(
          '${index + 1}. $name',
        ),
        const Spacer(),
        Text(
          '${items.length}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        Spacing.w16,
      ],
    ).paddingOnly(bottom: 8);
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 2.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xff999999)),
              ),
            );
          }),
        );
      },
    );
  }
}
