import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/general_info/models/general_info.model.dart';
import 'package:temple_adventures_admin/services/screenshot.service.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';
import 'package:temple_adventures_admin/widgets/screenshot_capture_fab.dart';
import '../../../../services/share.service.dart';
import '../../../../theme.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/date_selector.dart';
import '../../bloc/board_plan.cubit.dart';
import '../../models/boats.model.dart';
import '../widgets/boat_details_table.dart';
import '../widgets/general_info_table.dart';

class BoardPlanScreen extends StatefulWidget {
  const BoardPlanScreen({super.key});

  static MaterialPageRoute<dynamic> route() {
    return MaterialPageRoute(builder: (_) => BoardPlanScreen());
  }

  @override
  State<BoardPlanScreen> createState() => _BoardPlanScreenState();
}

class _BoardPlanScreenState extends State<BoardPlanScreen> {
  final GlobalKey _generalInfoKey = GlobalKey(); // To create a screenshot of General Info widget
  final GlobalKey _boatDetailsKey = GlobalKey(); // To create a screenshot of Boat Details widgets
  late final BoardPlanCubit _boardPlanCubit;

  @override
  void initState() {
    super.initState();
    // Save a reference to the cubit while the context is still active
    _boardPlanCubit = context.read<BoardPlanCubit>();
    
    // Fetch data when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentDate = _boardPlanCubit.state.selectedDate ?? DateTime.now();
      _boardPlanCubit.selectDate(currentDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Board Plan', description: 'See plans for selected date and boats'),
      floatingActionButton: buildFloatingActionButton(),
      body: SafeArea(
        child:
            BlocSelector<BoardPlanCubit, BoardPlanState, bool>(
              selector: (state) => state.status is BoardPlanLoading,
              builder: (context, loading) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        DateSelector(
                          selectedDate: context.read<BoardPlanCubit>().state.selectedDate ?? DateTime.now(),
                          onDateChange: (newDate) {
                            context.read<BoardPlanCubit>().selectDate(newDate);
                          },
                        ).paddingOnly(right: 10),

                        Spacing.h20,
                        BlocSelector<BoardPlanCubit, BoardPlanState, (List<Boat>, Boat?)>(
                          selector: (state) => (state.boats, state.selectedBoat),
                          builder: (context, _) {
                            final BoardPlanState state = context.read<BoardPlanCubit>().state;

                            return Column(
                              children: [
                                Wrap(
                                  runSpacing: 15,
                                  spacing: 15,
                                  children: [
                                    SelectableChip(
                                      onTap: () => context.read<BoardPlanCubit>().selectBoat(null),
                                      title: 'General Info',
                                      selected: state.selectedBoat == null,
                                    ),
                                    ...state.boats.map(
                                      (boat) => SelectableChip(
                                        onTap: () => context.read<BoardPlanCubit>().selectBoat(boat),
                                        selected: boat.id == state.selectedBoat?.id,

                                        title: boat.name,
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.selectedBoat == null)
                                  BlocSelector<BoardPlanCubit, BoardPlanState, GeneralInfo?>(
                                    selector: (state) => state.generalInfo,
                                    builder:
                                        (context, generalInfo) => Transform.scale(
                                          scale: 1,
                                          child: RepaintBoundary(
                                            key: _generalInfoKey,
                                            child: GeneralInfoTable(
                                              generalInfo: generalInfo,
                                              selectedDate:
                                                  context.read<BoardPlanCubit>().state.selectedDate ?? DateTime.now(),
                                            ),
                                          ),
                                        ).paddingAll(20).paddingOnly(bottom: 200),
                                  )
                                else
                                  BlocSelector<BoardPlanCubit, BoardPlanState, Boat?>(
                                    selector: (state) => state.selectedBoat,
                                    builder:
                                        (context, boat) =>
                                            Transform.scale(
                                              scale: 1.7,
                                              alignment: Alignment.topCenter,
                                              child: RepaintBoundary(
                                                key: _boatDetailsKey,
                                                child: BoatDetailsTable().paddingOnly(top: 20),
                                              ),
                                            ).paddingOnly(bottom: 1000).center,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    if (loading) LoadingOverlay(),
                  ],
                );
              },
            ).scrollable,
      ),
    );
  }

  Widget buildFloatingActionButton() {
    return BlocBuilder<BoardPlanCubit, BoardPlanState>(
      builder: (context, state) {
        // Check generalInfo exists and boats list is not empty
        final bool hasGeneralInfo = state.generalInfo != null;
        final bool hasBoats = state.boats.isNotEmpty;
        final bool hasCurrentViewData = state.selectedBoat != null || hasGeneralInfo;

        // Hide all FABs if no data exists
        if (!hasCurrentViewData && !hasBoats) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Single view capture FAB - show only if current view has data
            if (hasCurrentViewData)
              ScreenshotCaptureFAB.singleWidget(
                captureKey: state.selectedBoat == null ? _generalInfoKey : _boatDetailsKey,
                heroTag: "board_plan_share_fab",
                icon: Icons.share,
              ),

            // Add spacing only if both FABs are visible
            if (hasCurrentViewData && hasBoats) Spacing.h20,

            // Multi-capture FAB - show only if there are boats
            if (hasCurrentViewData)
              ScreenshotCaptureFAB.customFunction(
                captureFunction: () => _captureAllViews(),
                heroTag: "board_plan_capture_all_fab",
                icon: Icons.directions_boat_filled_rounded,
              ),
          ],
        );
      },
    );
  }

  /// Capture and share all views (General Info + All Boats)
  Future<void> _captureAllViews() async {
    // Get cubit reference FIRST, before any state changes
    final cubit = context.read<BoardPlanCubit>();
    final state = cubit.state;

    final List<File> capturedFiles = [];

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capturing all views...')),
      );

      // Capture General Info first
      cubit.selectBoat(null);
      await Future.delayed(const Duration(seconds: 1)); // Wait for UI to update

      if (state.generalInfo != null) {
        final generalInfoFile = await ScreenshotService.captureWidget(_generalInfoKey);
        if (generalInfoFile != null) {
          capturedFiles.add(generalInfoFile);
        }
      }

      // Capture all boats
      for (int i = 0; i < state.boats.length; i++) {
        final boat = state.boats[i];
        cubit.selectBoat(boat);
        await Future.delayed(const Duration(seconds: 1)); // Wait for data loading and UI update

        final boatFile = await ScreenshotService.captureWidget(_boatDetailsKey);
        if (boatFile != null) {
          capturedFiles.add(boatFile);
        }
      }

      // Reset to General Info after capturing all
      cubit.selectBoat(null);

      if (capturedFiles.isNotEmpty) {
        await ShareService.shareMultipleFiles(capturedFiles);

        // Cleanup after sharing
        await ShareService.cleanupFiles(capturedFiles);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error capturing screenshots: ${e.toString()}');
      }
      // Cleanup files on error
      await ShareService.cleanupFiles(capturedFiles);
    }
  }
}

class SelectableChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectableChip({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          color: selected ? lightSkyBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ).paddingSymmetric(horizontal: 10, vertical: 7),
      ),
    );
  }
}
