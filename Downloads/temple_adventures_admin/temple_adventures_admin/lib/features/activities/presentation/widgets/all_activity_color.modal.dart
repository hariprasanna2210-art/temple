import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/activities/bloc/all_activity_colors.cubit.dart';
import 'package:temple_adventures_admin/features/activities/presentation/screens/add_edit_activity_color.screen.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/modal_wrapper.dart';
import '../../../../theme.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../models/activity_color.model.dart';

class AllActivityColorModal extends StatefulWidget {
  const AllActivityColorModal({super.key});

  static Future<ActivityColor?> show(BuildContext context) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AllActivityColorModal();
      },
    );
  }

  @override
  State<AllActivityColorModal> createState() => _AllActivityColorModalState();
}

class _AllActivityColorModalState extends State<AllActivityColorModal> {
  @override
  void initState() {
    context.read<AllActivityColorsCubit>().fetchAllActivityColors();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
            color: lightBlueColor,
          ),
          child:
              Column(
                children: [
                  buildHeader(),
                  Spacing.h20,
                  InkWell(
                    onTap: () {
                      Navigator.push(context, AddEditActivityColorScreen.route());
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_box_outlined, size: 27),
                        Spacing.w16,
                        CustomTitle(title: 'Add New Color', fontSize: 14),
                      ],
                    ).paddingVertical(10),
                  ),
                  const _ActivityColorListView(),
                  Spacing.h10,
                ],
              ).paddingAll(20).scrollable,
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        CustomTitle(title: 'Select Color', fontSize: 20),
        Spacer(),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close),
        ),
      ],
    );
  }
}

class _ActivityColorListView extends StatelessWidget {
  const _ActivityColorListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllActivityColorsCubit, AllActivityColorsState>(
      builder: (context, state) {
        return state.status.when(
          initial: () => const SizedBox.shrink(),

          loading: () => CircularProgressIndicator().center,

          error: (message) => Text('Error: $message', style: const TextStyle(color: Colors.red)).center,

          success: (_) {
            if (state.colors.isEmpty) {
              return const EmptyStateMessage(
                message: 'No colors found',
              );
            }

            return Column(
              children:
                  state.colors.map((item) {
                    return InkWell(
                      onTap: () => Navigator.pop(context, item),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: item.color.toNormalColor(),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Spacing.w20,
                          Text(item.name, style: const TextStyle(color: Colors.black, fontSize: 14)),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.push(context, AddEditActivityColorScreen.route(activityColor: item));
                            },
                            icon: const Icon(Icons.edit, size: 15),
                          ),
                        ],
                      ).paddingVertical(3),
                    );
                  }).toList(),
            );
          },
        );
      },
    );
  }
}
