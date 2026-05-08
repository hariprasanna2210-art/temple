import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/conditions/bloc/all_conditions.cubit.dart';
import 'package:temple_adventures_admin/features/conditions/presentation/screens/add_edit_condition.screen.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_floating_action_button.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/date_selector.dart';
import '../../model/surface_conditions.model.dart';
import '../../model/water_conditions.model.dart';
import '../../widget/depth_expansion_panel_widget.dart';
import '../../widget/surface_condition_expansion_widget.dart';

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const ConditionsScreen());

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AllConditionsCubit>();
      cubit.resetToCurrentDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AllConditionsCubit>();
    return Scaffold(
      backgroundColor: lightBlueColor,
      body: SafeArea(
        child: BlocConsumer<AllConditionsCubit, AllConditionState>(
          listener: (context, state) {
            if (state.status is AllConditionError) {
              context.showSnackBar((state.status as AllConditionError).message);
            }
          },
          builder: (context, state) {
            if (state.status is AllConditionLoading) {
              return const LoadingOverlay();
            }
            if (state.status is AllConditionSuccess || state.status is AllConditionLoaded) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Spacing.h20,
                      DateSelector(
                        selectedDate: state.selectedDate,
                        onDateChange: (newDate) {
                          cubit.updateSelectedDate(newDate);
                        },
                      ).paddingSymmetric(horizontal: 27),
                      Spacing.h20,
                      _buildHeader(context),
                      Spacing.h25,
                    ],
                  ),
                  SizedBox(
                    height: Screen.height - 240,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          state.surfaceConditions.isNotEmpty
                              ? SurfaceConditionsExpansionWidget(
                                key: ValueKey('surface_${cubit.state.selectedReef}'),
                                disableTouches: true,
                                surfaceConditions: cubit.filteredSurfaceConditions,
                                selectedReef: cubit.state.selectedReef,
                                onChanged: (List<SurfaceConditions> surfaceConditions) {},
                              ).paddingSymmetric(horizontal: 27)
                              : SizedBox.shrink(),
                          Spacing.h25,
                          Container(
                            width: Screen.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: _buildGraph(context).paddingSymmetric(vertical: 20),
                          ).paddingSymmetric(horizontal: 20),
                          Spacing.h22,
                        ],
                      ),
                    ),
                  ),
                ],
              ).scrollable;
            }
            return const LoadingOverlay();
          },
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        onTap: () async {
          final refresh = await Navigator.push(context, AddEditConditionsScreen.route());
          if (refresh == true) {
            cubit.resetToCurrentDate();
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cubit = context.read<AllConditionsCubit>();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              cubit.state.reefs.map((reef) {
                final selected = reef == cubit.state.selectedReef;
                return GestureDetector(
                  onTap: () => cubit.onReefSelected(reef),
                  child: Container(
                    height: 27,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: selected ? skyBlueColor : Colors.white,
                    ),
                    child: Text(
                      reef,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ).paddingSymmetric(horizontal: 9, vertical: 5),
                  ).paddingOnly(right: 13),
                );
              }).toList(),
        ).paddingSymmetric(horizontal: 27),
      ),
    );
  }

  Widget buildButton({required Function onTap, required IconData icon}) {
    return SizedBox(
      height: 20,
      width: 20,
      child: IconButton(
        splashRadius: 30,
        padding: EdgeInsets.zero,
        onPressed: () => onTap(),
        icon: Icon(icon, color: Colors.black, size: 14),
      ),
    );
  }

  Widget _buildGraph(BuildContext context) {
    final cubit = context.read<AllConditionsCubit>();
    final levels = cubit.filteredWaterConditions;

    if (levels.isEmpty) {
      return const Center(child: Text('No entries found in selected reef'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: levels.map((e) => buildLevel(e)).toList(),
    );
  }

  Widget buildLevel(WaterConditions level) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          child: Center(child: Text('${level.depth} m')),
        ),
        Container(color: Colors.black.withOpacity(0.3), width: 1, height: 120),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  children: List.generate(
                    5,
                    (index) => Container(
                      color: Colors.black.withOpacity(0.05),
                      width: 3,
                      height: 1,
                    ).paddingOnly(top: 6, bottom: 6),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSlider(level.fish, SliderType.fishLife),
                    buildSlider(level.visibility, SliderType.visibility),
                    buildSlider(level.currents, SliderType.currents),
                  ],
                ),
              ],
            ),
            Container(
              color: Colors.black.withOpacity(0.05),
              width: 250,
              height: 1,
            ).paddingOnly(top: 10),
            RichText(
              text: TextSpan(
                text: level.updatedBy.fullName,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade800,
                  fontFamily: 'Nunito',
                ),
                children: [
                  TextSpan(
                    text: " (${DateFormat("hh:mm a").format(level.updatedAt.toLocal())})",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).paddingOnly(left: 5, top: 5),
          ],
        ),
      ],
    ).paddingSymmetric(horizontal: 5);
  }

  Widget buildSlider(int pos, SliderType type) {
    return Row(
      children: [
        SizedBox(
          width: Screen.width - 197,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5, pressedElevation: 1),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: pos * 1.0,
              onChanged: (_) {},
              activeColor: Colors.grey.withOpacity(0.5),
              inactiveColor: Colors.grey.withOpacity(0.5),
              thumbColor: Colors.black,
              divisions: 5,
              min: 0,
              max: 5,
            ),
          ),
        ),
        Text(getEmoji(type)).paddingOnly(right: 5),
        SizedBox(
          width: 80,
          child: Text(
            getStatus(pos, type),
            style: TextStyle(
              fontSize: 12,
              color: getColor(pos * 1.0, type == SliderType.currents),
            ),
          ),
        ),
      ],
    );
  }

  String getStatus(int pos, SliderType type) {
    final adjustedPos = pos.clamp(0, 4);

    switch (type) {
      case SliderType.fishLife:
        return ['No fish', 'Scattered fish', 'Lots of fish', 'Rare fish life', 'Whale shark'][adjustedPos];
      case SliderType.visibility:
        return [
          "Can't see computer",
          "Can't see dive buddy",
          "Can see reef",
          "Can see boat",
          "Can see everything",
        ][adjustedPos];
      case SliderType.currents:
        return [
          'No current',
          'Mild current',
          'Moderate current',
          'Strong current',
          'Where is my passport ?',
        ][adjustedPos];
    }
  }

  String getEmoji(SliderType type) {
    switch (type) {
      case SliderType.fishLife:
        return '🐠';
      case SliderType.visibility:
        return '👀';
      case SliderType.currents:
        return '🌊';
    }
  }
}
