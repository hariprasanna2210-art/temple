import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../theme.dart';
import '../model/water_conditions.model.dart';

class DepthExpansionPanelWidget extends StatefulWidget {
  const DepthExpansionPanelWidget({
    super.key,
    required this.level,
    required this.onDeletePressed,
    required this.onChanged,
  });

  final WaterConditions level;
  final Function onDeletePressed;
  final Function(double fish, double visibility, double currents) onChanged;

  @override
  State<DepthExpansionPanelWidget> createState() => _DepthExpansionPanelWidgetState();
}

class _DepthExpansionPanelWidgetState extends State<DepthExpansionPanelWidget> {
  bool isExpanded = false;

  late double fishLife = (widget.level.fish) * 1.0;
  late double visibility = (widget.level.visibility) * 1.0;
  late double currents = (widget.level.currents) * 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${widget.level.depth} meters',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  padding: const EdgeInsets.all(0),
                  visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                  splashRadius: 20,
                  iconSize: 13,
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onDeletePressed();
                  },
                ),
                IconButton(
                  visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                  padding: const EdgeInsets.all(0),
                  splashRadius: 20,
                  iconSize: 20,
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
              ],
            ).paddingOnly(left: 20),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  buildConditionSlider(
                    SliderType.fishLife,
                  ),
                  buildConditionSlider(
                    SliderType.visibility,
                  ),
                  buildConditionSlider(
                    SliderType.currents,
                  ),
                  const SizedBox(height: 15),
                  buildWaterConditions(
                    title: 'Updated By',
                    text: widget.level.updatedBy.fullName,
                  ),
                  const SizedBox(height: 10),
                  buildWaterConditions(
                    title: 'Updated Time',
                    text: DateFormat('dd MMM yyyy @ hh:mm a').format(widget.level.updatedAt),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
          ],
        ),
      ),
    );
  }

  ///==================UI==================///

  Widget buildWaterConditions({required String title, required String text}) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          ' :   $text',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ).paddingSymmetric(horizontal: 20);
  }

  Widget buildConditionSlider(SliderType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getSliderTitle(type),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ).paddingOnly(left: 20),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                    pressedElevation: 1,
                  ),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                ),
                child: Slider(
                  value: getValue(type),
                  onChanged: (double value) {
                    switch (type) {
                      case SliderType.fishLife:
                        fishLife = value;
                        break;
                      case SliderType.visibility:
                        visibility = value;
                        break;
                      case SliderType.currents:
                        currents = value;
                        break;
                    }
                    setState(() {});
                    widget.onChanged(fishLife, visibility, currents);
                  },
                  activeColor: grey.withOpacity(0.5),
                  inactiveColor: grey.withOpacity(0.5),
                  thumbColor: Colors.black,
                  divisions: 5,
                  min: 0,
                  max: 5,
                ),
              ),
            ),
            SizedBox(
              width: 67,
              child: Text(
                getConditions(type),
                style: TextStyle(
                  fontSize: 13,
                  color: getColor(getValue(type), type == SliderType.currents),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ).paddingOnly(right: 10, left: 5),
      ],
    ).paddingOnly(bottom: 5);
  }

  double getValue(SliderType type) {
    switch (type) {
      case SliderType.fishLife:
        return fishLife;
      case SliderType.visibility:
        return visibility;
      case SliderType.currents:
        return currents;
    }
  }

  String getConditions(SliderType type) {
    switch (type) {
      case SliderType.fishLife:
        if (fishLife == 0) return 'No fish';
        if (fishLife == 1) return 'Scattered fish';
        if (fishLife == 2) return 'Lots of fish';
        if (fishLife == 3) return 'Rare fish life';
        return 'Whale shark';
      case SliderType.visibility:
        if (visibility == 0) return "Can't see computer";
        if (visibility == 1) return "Can't see dive buddy";
        if (visibility == 2) return 'Can see reef';
        if (visibility == 3) return 'Can see boat';
        return 'Can see everything';
      case SliderType.currents:
        if (currents == 0) return 'No current';
        if (currents == 1) return 'Mild current';
        if (currents == 2) return 'Moderate current';
        if (currents == 3) return 'Strong current';
        return 'Where is my passport ?';
    }
  }
}

enum SliderType {
  fishLife,
  visibility,
  currents,
}

Color getColor(double value, bool isCurrents) {
  if (isCurrents) {
    if (value == 4) return const Color(0xffBE0000);
    if (value == 3) return const Color(0xffBE0000);
    if (value == 2) return const Color(0xffFF7A00);
    if (value == 1) return const Color(0xffFF7A00);
    if (value == 0) return const Color(0xff009429);
    return const Color(0xffBE0000);
  }
  if (value == 0) return const Color(0xffBE0000);
  if (value == 1) return const Color(0xffBE0000);
  if (value == 2) return const Color(0xffFF7A00);
  if (value == 3) return const Color(0xffFF7A00);
  if (value == 4) return const Color(0xff009429);
  return const Color(0xff009429);
}

String getSliderTitle(SliderType type) {
  switch (type) {
    case SliderType.fishLife:
      return 'Fish Life';
    case SliderType.visibility:
      return 'Visibility';
    case SliderType.currents:
      return 'Currents';
  }
}
