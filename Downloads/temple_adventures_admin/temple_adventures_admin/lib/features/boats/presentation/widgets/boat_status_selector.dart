import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../enums/boat_status.enum.dart';

class BoatStatusSelector extends StatefulWidget {
  const BoatStatusSelector({super.key, required this.initialStatus, required this.onChanged});

  final BoatStatus? initialStatus;
  final Function(BoatStatus status) onChanged;

  @override
  State<BoatStatusSelector> createState() => _BoatStatusSelectorState();
}

class _BoatStatusSelectorState extends State<BoatStatusSelector> {
  BoatStatus currentStatus = BoatStatus.unknown;

  @override
  void initState() {
    currentStatus = widget.initialStatus ?? BoatStatus.unknown;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = BoatStatus.values.indexOf(currentStatus);
    final bool canGoLeft = currentIndex > 0;
    final bool canGoRight = currentIndex < BoatStatus.values.length - 1;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (canGoLeft) {
              setState(() {
                currentStatus = BoatStatus.values[currentIndex - 1];
              });
              widget.onChanged(currentStatus);
            }
          },
          child: Container(
            height: 33,
            width: 27,
            decoration: BoxDecoration(
              color: currentStatus.color,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
            child: const Icon(Icons.arrow_left, size: 16),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          height: 33,
          decoration: BoxDecoration(color: currentStatus.color),
          child: Text(
            currentStatus.prettyName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ).paddingOnly(left: 15, right: 15, top: 8),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: () {
            if (canGoRight) {
              setState(() {
                currentStatus = BoatStatus.values[currentIndex + 1];
              });
              widget.onChanged(currentStatus);
            }
          },
          child: Container(
            height: 33,
            width: 27,
            decoration: BoxDecoration(
              color: currentStatus.color,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
            child: const Icon(Icons.arrow_right, size: 16),
          ),
        ),
      ],
    );
  }
}

extension _BoatStatusX on BoatStatus {
  Color get color => switch (this) {
    BoatStatus.unknown => Colors.black26,
    BoatStatus.ready => Colors.grey.shade400,
    BoatStatus.waitingForCaptains => Colors.orange.shade300,
    BoatStatus.leftHarbour => Colors.red.shade400,
    BoatStatus.reachedDiveSite => Colors.green.shade300,
    BoatStatus.diving => skyBlueColor.withOpacity(0.5),
    BoatStatus.divesDone => Colors.purpleAccent.shade100,
    BoatStatus.docked => Colors.yellow.shade300,
  };
}