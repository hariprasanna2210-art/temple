import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/conditions/bloc/all_conditions.cubit.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../user/bloc/user.cubit.dart';
import '../../bloc/add_edit_condition.cubit.dart';
import '../../model/surface_conditions.model.dart';
import '../../model/water_conditions.model.dart';
import '../../widget/depth_expansion_panel_widget.dart';
import '../../widget/surface_condition_expansion_widget.dart';

class AddEditConditionsScreen extends StatefulWidget {
  const AddEditConditionsScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AddEditConditionsScreen());

  @override
  State<AddEditConditionsScreen> createState() => _AddEditConditionsScreenState();
}

class _AddEditConditionsScreenState extends State<AddEditConditionsScreen> {
  final TextEditingController depthTED = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AllConditionsCubit>();
      cubit.fetchSurfaceCondition(DateTime.now());
      cubit.fetchWaterCondition(DateTime.now());
    });
    super.initState();
  }

  void _onSavePressed() {
    final addEditCubit = context.read<AddEditConditionCubit>();
    final allCubit = context.read<AllConditionsCubit>();
    addEditCubit.onConditionSubmitAll(
      context,
      allCubit.state.surfaceConditions,
      allCubit.state.waterConditions,
    );
  }

  void _onBackPressed() {
    _showAlert(
      context: context,
      content: 'All your changes will be discarded.',
      title: 'Are you sure,you want to go back?',
      onOkayPressed: () {
        final allCubit = context.read<AllConditionsCubit>();
        allCubit.updateSelectedDate(allCubit.state.selectedDate);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditConditionCubit, AddEditConditionState>(
      listener: (context, state) {
        if (state.status is AddEditConditionLoading) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status is AddEditConditionError) {
          Navigator.of(context, rootNavigator: true).pop();
          context.showSnackBar((state.status as AddEditConditionError).message);
        }

        if (state.status is AddEditConditionSuccess && (state.status as AddEditConditionSuccess).shouldPop) {
          Navigator.of(context, rootNavigator: true).pop();
          context.showSnackBar('Conditions Saved Successfully');
          Navigator.pop(context, true);
        }
      },

      child: BlocConsumer<AllConditionsCubit, AllConditionState>(
        listener: (context, state) {
          if (state.status is AllConditionError) {
            context.showSnackBar((state.status as AllConditionError).message);
          }
          if (state.status is AllConditionSuccess) {
            context.showSnackBar((state.status as AllConditionSuccess).message);
          }
        },
        builder: (context, state) {
          if (state.status is AllConditionLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator().center,
              ),
            );
          }
          if (state.status is AllConditionError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton.flat(
                      text: 'Retry',
                      onTap: () {
                        context.read<AllConditionsCubit>().fetchSurfaceCondition(
                          context.read<AllConditionsCubit>().state.selectedDate,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.status is AllConditionLoaded || state.status is AllConditionSuccess) {
            final allCubit = context.read<AllConditionsCubit>();
            final filteredWater = allCubit.filteredWaterConditions;

            return WillPopScope(
              onWillPop: () async {
                _showAlert(
                  context: context,
                  content: 'All your changes will be discarded.',
                  title: 'Are you sure you want to go back?',
                  onOkayPressed: () {
                    final allCubit = context.read<AllConditionsCubit>();
                    allCubit.updateSelectedDate(state.selectedDate);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                );
                return false;
              },
              child: Scaffold(
                backgroundColor: lightBlueColor,
                appBar: buildAppBar(context, _onSavePressed, _onBackPressed),
                floatingActionButton: _buildFloatingButton(context, state),
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacing.h30,
                        SizedBox(
                          width: 103,
                          child: Text(
                            DateFormat('dd-MMM-yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).paddingSymmetric(horizontal: 30),
                        Spacing.h30,
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                state.reefs.map((reef) {
                                  return _buildChip(
                                    reefName: reef,
                                    isSelected: state.selectedReef == reef,
                                    onTap: () => allCubit.onReefSelected(reef),
                                  );
                                }).toList(),
                          ).paddingSymmetric(horizontal: 27),
                        ),
                        Spacing.h30,

                        buildSurfaceConditionsExpansionWidget(allCubit).paddingSymmetric(horizontal: 27),
                        Spacing.h30,
                        if (filteredWater.isNotEmpty)
                          const Text(
                            'Water Conditions:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ).paddingSymmetric(horizontal: 27),
                        Spacing.h30,
                        SizedBox(
                          height: Screen.height - 373,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (filteredWater.isEmpty)
                                  SizedBox(
                                    height: Screen.height / 3,
                                    width: Screen.width,
                                    child: const Center(
                                      child: Text(
                                        'Please add water conditions by clicking below',
                                      ),
                                    ),
                                  ),
                                ...filteredWater.asMap().entries.map((entry) {
                                  final water = entry.value;
                                  final mainListIndex = state.waterConditions.indexWhere(
                                    (condition) =>
                                        condition.reef == water.reef &&
                                        condition.depth == water.depth &&
                                        condition.date == water.date,
                                  );
                                  return DepthExpansionPanelWidget(
                                    key: ValueKey('water_${water.reef}_${water.depth}'),
                                    level: water,
                                    onChanged: (fish, vis, curr) {
                                      if (mainListIndex != -1) {
                                        final updatedWater = water.copyWith(
                                          fish: fish.toInt(),
                                          visibility: vis.toInt(),
                                          currents: curr.toInt(),
                                        );

                                        allCubit.updateWaterConditionAtIndex(
                                          index: mainListIndex,
                                          updatedCondition: updatedWater,
                                        );
                                      }
                                    },
                                    onDeletePressed: () {
                                      _showAlert(
                                        context: context,
                                        title: 'Delete Condition?',
                                        content: 'This item will be removed completely.',
                                        onOkayPressed: () {
                                          if (mainListIndex != -1) {
                                            allCubit.deleteWaterConditionByIndex(mainListIndex);
                                          }
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ).paddingOnly(bottom: 12, left: 27, right: 27);
                                }),
                                Spacing.h50,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return EmptyStateMessage(message: 'Something went wrong');
        },
      ),
    );
  }

  Widget _buildChip({
    required String reefName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 13),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? skyBlueColor : Colors.white,
        ),
        child: Text(
          reefName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context, VoidCallback onSavePressed, VoidCallback onBackPressed) {
    return AppBar(
      toolbarHeight: 70,
      leading: IconButton(
        color: Colors.black,
        iconSize: 17,
        onPressed: onBackPressed,
        icon: const Icon(Icons.arrow_back_ios),
      ),
      actions: [
        GestureDetector(
          onTap: onSavePressed,
          child: Center(
            child: Container(
              height: 30,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
              ),
              child: const Center(
                child: Text(
                  'Save',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ).paddingOnly(right: 30),
          ),
        ),
      ],
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  Widget buildSurfaceConditionsExpansionWidget(
    AllConditionsCubit cubit,
  ) {
    final conditions =
        cubit.filteredSurfaceConditions.map((c) {
          return c.copyWith(
            temp: (c.temp == 0 || c.temp.isNaN) ? 20 : c.temp,
          );
        }).toList();
    return SurfaceConditionsExpansionWidget(
      key: ValueKey('surface_${cubit.state.selectedReef}'),
      surfaceConditions: conditions,
      onChanged: (List<SurfaceConditions> surfaceConditions) {
        final updatedCondition = surfaceConditions.firstWhere(
          (condition) => condition.reefName == cubit.state.selectedReef,
        );
        cubit.updateSurfaceConditionValue(
          reefName: cubit.state.selectedReef,
          temp: updatedCondition.temp,
          speed: updatedCondition.speed,
          currents: updatedCondition.currents,
          swell: updatedCondition.swell,
        );
      },
      selectedReef: cubit.state.selectedReef,
      disableTouches: false,
    );
  }

  Widget _buildFloatingButton(BuildContext context, AllConditionState state) {
    return FloatingActionButton(
      elevation: 0,
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          barrierColor: Colors.black.withOpacity(0.3),
          isDismissible: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Depth',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            hintText: 'Add depth',
                            controller: depthTED,
                            keyboardType: TextInputType.number,
                            validator: (_) => null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              AppButton.miniFlat(
                                isSecondary: true,
                                text: 'Cancel',
                                onTap: () {
                                  Navigator.pop(context);
                                  depthTED.clear();
                                },
                              ),
                              const Spacer(),
                              AppButton.miniFlat(
                                text: 'Submit',
                                onTap: () {
                                  final cubit = context.read<AllConditionsCubit>();
                                  final newCondition = WaterConditions(
                                    fish: 5,
                                    currents: 0,
                                    updatedBy: context.read<UserCubit>().state.currentUser!,
                                    date: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    visibility: 5,
                                    reef: cubit.state.selectedReef,
                                    depth: int.parse(depthTED.text),
                                  );
                                  final isAlreadyExist = cubit.filteredWaterConditions.any(
                                    (condition) => condition.depth == newCondition.depth,
                                  );
                                  if (isAlreadyExist) {
                                    Navigator.pop(context);
                                    depthTED.clear();
                                    context.showSnackBar(
                                      'A water condition for ${newCondition.reef} at depth ${newCondition.depth} already exists.',
                                    );
                                    return;
                                  }
                                  cubit.addWaterConditions(newCondition);
                                  depthTED.clear();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAlert({
    required BuildContext context,
    required String title,
    required String content,
    required Function onOkayPressed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
          actions: <Widget>[
            Row(
              children: [
                AppButton.miniFlat(
                  isSecondary: true,
                  text: 'Cancel',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Spacer(),
                AppButton.miniFlat(
                  text: 'Okay',
                  onTap: () {
                    onOkayPressed();
                  },
                ),
              ],
            ).paddingSymmetric(horizontal: 10),
          ],
        );
      },
    );
  }
}
