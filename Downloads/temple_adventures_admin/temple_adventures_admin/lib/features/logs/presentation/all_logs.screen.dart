import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';

import '../../../widgets/custom_app_bar.dart';
import '../bloc/all_logs.cubit.dart';
import '../models/log.model.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllLogsScreen());

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  late final AllLogsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AllLogsCubit>();
    _cubit.fetchInitialLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Logs', description: 'All important actions performed by all users'),
      body: SafeArea(
        child: BlocConsumer<AllLogsCubit, AllLogsState>(
          listener: (context, state) {
            if (state.status is AllLogsError) {
              context.showSnackBar((state.status as AllLogsError).message);
            }
          },
          builder: (context, state) {
            if (state.status is AllLogsInitial || state.status is AllLogsLoading) {
              return const CircularProgressIndicator().center;
            }
            if (state.logs.isEmpty) {
              return const Text("No logs found").center;
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: state.logs.length + (_cubit.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < state.logs.length) {
                    final log = state.logs[index];
                    return RepaintBoundary(
                      child: _LogListTile(currentLog: log),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _cubit.fetchMoreLogs();
    }
  }

  Future<void> _onRefresh() => _cubit.refresh();
}

class _LogListTile extends StatelessWidget {
  final LogModel currentLog;

  const _LogListTile({required this.currentLog});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentLog.actionType.color,
              ),
              child:
                  currentLog.shouldShowEntityId
                      ? Text(
                        '${currentLog.entityId}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ).center
                      : Icon(currentLog.actionType.icon).center,
            ),
            Spacing.w15,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    currentLog.actionType.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacing.h2,
                Text(
                  currentLog.createdBy.fullName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentLog.createdAt?.formatDDMMYYYY ?? '',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacing.h4,
                Text(
                  currentLog.createdAt?.formatHHMM ?? '',
                  style: const TextStyle(
                    color: Color(0xff02D2F9),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ).paddingAll(12),
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.grey.shade300,
        ).paddingSymmetric(vertical: 12),
      ],
    );
  }
}

extension _ActionTypeX on ActionType {
  String get title => switch (this) {
    ActionType.signedIn => 'Signed In',
    ActionType.signedOut => 'Signed Out',
    ActionType.bookingCreated => 'Booking Created',
    ActionType.quickBookingCreated => 'Quick Booking Created',
    ActionType.quickBookingEdited => 'Quick Booking Edited',
    ActionType.quickBookingDeleted => 'Quick Booking Deleted',
    ActionType.bookingDeleted => 'Booking Deleted',
    ActionType.bookingPaxDeleted => 'PAX Deleted',
    ActionType.bookingEdited => 'Booking Edited',
    ActionType.eventCreated => 'Event Created',
    ActionType.eventEdited => 'Event Edited',
    ActionType.eventDeleted => 'Event Deleted',
    ActionType.addActivity => 'Added Activity',
    ActionType.editActivity => 'Edited Activity',
    ActionType.deleteActivity => 'Activity Deleted',
    ActionType.addEmployee => 'Added Employee',
    ActionType.editEmployee => 'Edited Employee',
    ActionType.deleteEmployee => 'Deleted Employee',
  };

  IconData get icon => switch (this) {
    ActionType.signedIn => Icons.login_outlined,
    ActionType.signedOut => Icons.logout_outlined,
    ActionType.bookingCreated => Icons.add_box,
    ActionType.quickBookingCreated => Icons.flash_on,
    ActionType.quickBookingEdited => Icons.flash_on,
    ActionType.quickBookingDeleted => Icons.delete,
    ActionType.bookingDeleted => Icons.delete,
    ActionType.bookingPaxDeleted => Icons.person_remove,
    ActionType.bookingEdited => Icons.edit,
    ActionType.eventCreated => Icons.event,
    ActionType.eventEdited => Icons.edit_calendar,
    ActionType.eventDeleted => Icons.event_busy,
    ActionType.addActivity => Icons.sports_esports,
    ActionType.editActivity => Icons.edit_attributes,
    ActionType.deleteActivity => Icons.edit_attributes,
    ActionType.addEmployee => Icons.manage_accounts,
    ActionType.editEmployee => Icons.manage_accounts,
    ActionType.deleteEmployee => Icons.person_remove_alt_1,
  };

  Color get color {
    switch (this) {
      case ActionType.bookingPaxDeleted:
        return Colors.orange;
      default:
        return skyBlueColor;
    }
  }
}

extension LogModelX on LogModel {
  String? get entityId => additionalInformation['id']?.toString();
  bool get hasEntity => entityId != null;

  bool get shouldShowEntityId {
    const bookingActions = [
      ActionType.bookingCreated,
      ActionType.quickBookingCreated,
      ActionType.quickBookingEdited,
      ActionType.quickBookingDeleted,
      ActionType.bookingEdited,
      ActionType.bookingDeleted,
      ActionType.bookingPaxDeleted,
    ];

    const employeeActions = [
      ActionType.addEmployee,
      ActionType.editEmployee,
      ActionType.deleteEmployee,
    ];

    return (bookingActions.contains(actionType) || employeeActions.contains(actionType)) && hasEntity;
  }
}
