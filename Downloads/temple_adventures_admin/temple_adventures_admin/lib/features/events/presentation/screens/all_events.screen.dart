import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/events/bloc/all_events.cubit.dart';
import 'package:temple_adventures_admin/features/events/widgets/add_edit_event.modal.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_floating_action_button.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';
import 'package:temple_adventures_admin/widgets/yes_or_no_dialog.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../models/event.model.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllEventsScreen());

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllEventsCubit>().fetchAllEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Events', description: 'All Events'),
      floatingActionButton: CustomFloatingActionButton(
        onTap: () async => AddEditEventModal.show(context),
      ),
      body: SafeArea(
        child: BlocConsumer<AllEventsCubit, AllEventsState>(
          listener: (context, state) {
            if (state.status is AllEventsError) {
              context.showSnackBar((state.status as AllEventsError).message);
            }
            if (state.status is AllEventsSuccess) {
              context.showSnackBar((state.status as AllEventsSuccess).message);
            }
          },
          builder: (context, state) {
            if (state.status is AllEventsInitial || state.status is AllEventsLoading) {
              return LoadingOverlay();
            }
            if (state.events.isEmpty) {
              return const EmptyStateMessage(
                message: 'No events found',
              ).center;
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];
                return _EventListTile(event: event);
              },
            );
          },
        ),
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final EventModel event;

  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Screen.width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyValuePair(
            title: 'Session Name',
            value: event.sessionName,
          ),
          Spacing.h8,
          KeyValuePair(
            title: 'Location',
            value: event.location,
          ),
          Spacing.h8,
          KeyValuePair(
            title: 'Date & Time',
            value: event.eventDateTime.formatFullDateTime,
          ),
          Spacing.h8,
          KeyValuePair(
            title: 'Contact Person',
            value: event.contactPerson.fullName,
          ),
          Spacing.h15,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Delete button
              AppButton.miniFlat(
                text: 'Delete',
                onTap: () async {
                  if (event.id == null) return;

                  final shouldDelete = await YesOrNoDialog.show(
                    context,
                    title: 'Are you sure to delete this event ?',
                    content: '${event.sessionName} will be completely deleted',
                  );
                  if (!shouldDelete) return;

                  if (context.mounted) context.read<AllEventsCubit>().deleteEvent(event.id!);
                },
              ),
              //Edit button
              AppButton.miniFlat(
                text: 'Edit',
                onTap: () async => AddEditEventModal.show(context, event: event),
              ),
            ],
          ).paddingSymmetric(horizontal: 6),
          Spacing.h20,
          Row(
            children: [
              Text(
                'Created By -',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              Spacing.w6,
              Text(
                event.createdBy.fullName,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ],
          ),
        ],
      ).paddingAll(16),
    ).marginOnly(bottom: 12, top: 5).paddingSymmetric(horizontal: 10, vertical: 5);
  }
}
