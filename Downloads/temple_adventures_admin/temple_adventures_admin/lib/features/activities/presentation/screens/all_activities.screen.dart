import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/activities/presentation/screens/add_edit_activity.screen.dart';
import 'package:temple_adventures_admin/features/user/enums/access_levels.enum.dart';
import 'package:temple_adventures_admin/utils/access_levels.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_floating_action_button.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';
import '../../../../theme.dart';
import '../../../../utils/debouncer.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../bloc/all_activities.cubit.dart';
import '../../models/activity.model.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllActivitiesScreen());

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  late final TextEditingController _searchTED;
  late final Debouncer _searchUpdateDebouncer;

  @override
  void initState() {
    super.initState();
    _searchTED = TextEditingController();
    _searchUpdateDebouncer = Debouncer();
    // Only fetch if list is empty (first load)
    final currentState = context.read<AllActivitiesCubit>().state;
    if (currentState.activities.isEmpty) {
      context.read<AllActivitiesCubit>().fetchAllActivities();
    }
  }

  @override
  void dispose() {
    _searchTED.dispose();
    _searchUpdateDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'All Activities', description: 'All Activities'),
      floatingActionButton: AccessLevelWidget(
        accessLevel: AccessLevels.addActivity,
        child: CustomFloatingActionButton(
          onTap: () => Navigator.push(context, AddEditActivityScreen.route()),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AllActivitiesCubit, AllActivitiesState>(
          listener: (context, state) {
            if (state.status is AllActivitiesStateError) {
              context.showSnackBar((state.status as AllActivitiesStateError).message);
            }
          },
          builder: (context, state) => state.status.when(
            initial: () => LoadingOverlay(),
            loading: () => LoadingOverlay(),
            loaded: () => Column(
              children: [
                AppTextField(
                  controller: _searchTED,
                  onChanged: (_) => _searchUpdateDebouncer(() => setState(() {})),
                  labelText: 'Search activity...',
                  border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                ).paddingAll(20),
                Expanded(
                  child: BlocSelector<AllActivitiesCubit, AllActivitiesState, List<Activity>>(
                    selector: (state) => state.activities,
                    builder: (context, activities) {
                      return _ActivityList(
                        activities: activities,
                        query: _searchTED.text.toLowerCase(),
                      );
                    },
                  ),
                ),
              ],
            ),
            error: (error) => Text(error).center,
          ),
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<Activity> activities;
  final String query;

  const _ActivityList({
    required this.activities,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = activities.where((a) => !a.isDeleted).toList();

    if (query.isNotEmpty) {
      filtered = filtered.where((a) => a.name.toLowerCase().contains(query)).toList();
    }

    if (filtered.isEmpty) {
      return const EmptyStateMessage(
        message: 'No activities found',
      ).center;
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final activity = filtered[index];
        return _ActivityListTile(activity);
      },
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  final Activity activity;

  const _ActivityListTile(this.activity);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Check if user has permission to edit activities
        if (AccessLevelChecker.canEditActivity(context)) {
          Navigator.push(context, AddEditActivityScreen.route(activity: activity));
        } else {
          // Show message that user doesn't have permission
          context.showSnackBar('You don\'t have permission to edit activities');
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: skyBlueColor,
            child: Text(activity.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(activity.name, style: const TextStyle(fontSize: 12)),
          trailing: Text('${activity.price}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
