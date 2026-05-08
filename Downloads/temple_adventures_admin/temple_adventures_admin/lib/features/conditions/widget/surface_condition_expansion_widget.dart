import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../theme.dart';
import '../model/surface_conditions.model.dart';

class SurfaceConditionsExpansionWidget extends StatefulWidget {
  SurfaceConditionsExpansionWidget({
    required this.surfaceConditions,
    required this.selectedReef,
    required this.onChanged,
    required this.disableTouches,
    super.key,
  });

  final List<SurfaceConditions> surfaceConditions;
  final String selectedReef;
  final Function(List<SurfaceConditions> surfaceConditions) onChanged;
  final bool disableTouches;

  final SurfaceConditionsExpansionWidgetState depthExpansionPanelWidgetState = SurfaceConditionsExpansionWidgetState();

  @override
  State<SurfaceConditionsExpansionWidget> createState() {
    // ignore: no_logic_in_create_state
    return depthExpansionPanelWidgetState;
  }

  void closeExpansion() {
    depthExpansionPanelWidgetState.closeExpansion();
  }
}

class SurfaceConditionsExpansionWidgetState extends State<SurfaceConditionsExpansionWidget> {
  bool isExpanded = false;

  late double surfaceTemp = (currentConditions?.temp ?? 0) * 1.0;
  late double surfaceCurrents = (currentConditions?.currents ?? 0) * 1.0;
  late double windSpeed = (currentConditions?.speed ?? 0) * 1.0;
  late double swell = (currentConditions?.swell ?? 0) * 1.0;

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
                const Text(
                  'Surface Conditions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
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
                  buildConditionSlider(SurfaceSlider.surfaceTemp),
                  buildConditionSlider(SurfaceSlider.surfaceCurrent),
                  buildConditionSlider(SurfaceSlider.windSpeed),
                  buildConditionSlider(SurfaceSlider.swell),
                  const SizedBox(height: 15),
                  buildWaterConditions(
                    title: 'Updated By',
                    text: currentConditions?.updatedBy.fullName ?? '-',
                  ),
                  const SizedBox(height: 10),
                  if (currentConditions?.updatedAt != null)
                    buildWaterConditions(
                      title: 'Updated Time',
                      text: DateFormat('dd MMM yyyy @ hh:mm a').format(
                        currentConditions!.updatedAt,
                      ),
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

  Widget buildConditionSlider(SurfaceSlider type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getSliderTitle(type),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ).paddingOnly(left: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                child: AbsorbPointer(
                  absorbing: widget.disableTouches,
                  child: Slider(
                    value: getValue(type),
                    onChanged: (double value) {
                      switch (type) {
                        case SurfaceSlider.surfaceTemp:
                          surfaceTemp = value;
                          break;
                        case SurfaceSlider.surfaceCurrent:
                          surfaceCurrents = value;
                          break;
                        case SurfaceSlider.windSpeed:
                          windSpeed = value;
                          break;
                        case SurfaceSlider.swell:
                          swell = value;
                          break;
                      }
                      setState(() {});
                      updateConditions();
                      widget.onChanged(widget.surfaceConditions);
                    },
                    activeColor: grey.withOpacity(0.5),
                    inactiveColor: grey.withOpacity(0.5),
                    thumbColor: Colors.black,
                    divisions: (SurfaceSlider.surfaceTemp == type) ? 15 : 5,
                    min: (SurfaceSlider.surfaceTemp == type) ? 20 : 0,
                    max: (SurfaceSlider.surfaceTemp == type) ? 35 : 5,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 67,
              child: Text(
                getConditions(type),
                style: TextStyle(
                  fontSize: 13,
                  color: getColor(
                    getValue(type),
                    type == SurfaceSlider.surfaceTemp,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).paddingOnly(top: 10),
          ],
        ).paddingOnly(right: 10, left: 5),
      ],
    ).paddingOnly(bottom: 5);
  }

  Color getColor(double value, bool isTemp) {
    if (isTemp) {
      // RED
      if ([20, 21, 22, 35, 34, 33].contains(value)) return const Color(0xffBE0000);
      // ORANGE
      if ([23, 24, 25, 32, 31, 30].contains(value)) return const Color(0xffFF7A00);
      // GREEN
      if ([26, 27, 28, 29].contains(value)) return const Color(0xff009429);
    }
    if (value == 0) return const Color(0xff009429);
    if (value == 1) return const Color(0xff009429);
    if (value == 2) return const Color(0xffFF7A00);
    if (value == 3) return const Color(0xffFF7A00);
    if (value == 4) return const Color(0xffBE0000);
    return const Color(0xffBE0000);
  }

  String getSliderTitle(SurfaceSlider type) {
    switch (type) {
      case SurfaceSlider.surfaceTemp:
        return 'Surface Temperature';
      case SurfaceSlider.surfaceCurrent:
        return 'Surface Currents';
      case SurfaceSlider.windSpeed:
        return 'Wind Speed';
      case SurfaceSlider.swell:
        return 'Swell';
    }
  }

  String getConditions(SurfaceSlider type) {
    switch (type) {
      case SurfaceSlider.surfaceTemp:
        return surfaceTemp.toString();
      case SurfaceSlider.surfaceCurrent:
        if (surfaceCurrents == 0) return 'No current';
        if (surfaceCurrents == 1) return 'Mild current';
        if (surfaceCurrents == 2) return 'Moderate current';
        if (surfaceCurrents == 3) return 'Strong current';
        return 'Where is my passport ?';
      case SurfaceSlider.windSpeed:
        if (windSpeed == 0) return 'Gentle breeze';
        if (windSpeed == 1) return 'Light winds';
        if (windSpeed == 2) return 'Strong winds ';
        if (windSpeed == 3) return 'Storm';
        return 'Boat is flying';
      case SurfaceSlider.swell:
        if (swell == 0) return 'Pool like';
        if (swell == 1) return 'Mild';
        if (swell == 2) return 'Big';
        if (swell == 3) return 'Very big';
        return 'Stay at home';
    }
  }

  double getValue(SurfaceSlider type) {
    switch (type) {
      case SurfaceSlider.surfaceCurrent:
        return surfaceCurrents;
      case SurfaceSlider.surfaceTemp:
        return surfaceTemp;
      case SurfaceSlider.windSpeed:
        return windSpeed;
      case SurfaceSlider.swell:
        return swell;
    }
  }

  SurfaceConditions? get currentConditions {
    for (SurfaceConditions cond in widget.surfaceConditions) {
      if (cond.reefName == widget.selectedReef) {
        return cond;
      }
    }
    return null;
  }

  void updateConditions() {
    for (int i = 0; i < widget.surfaceConditions.length; i++) {
      if (widget.surfaceConditions[i].reefName == widget.selectedReef) {
        widget.surfaceConditions[i] = widget.surfaceConditions[i].copyWith(
          temp: surfaceTemp,
          currents: surfaceCurrents,
          speed: windSpeed,
          swell: swell,
        );
      }
    }
  }

  void closeExpansion() {
    setState(() {
      isExpanded = false;
      log(isExpanded.toString());
    });
  }
}

enum SurfaceSlider {
  surfaceTemp,
  surfaceCurrent,
  windSpeed,
  swell,
}
