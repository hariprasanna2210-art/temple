import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../activities/bloc/all_activities.cubit.dart';
import '../../../activities/models/activity.model.dart';

class ActivityDropdown extends StatefulWidget {
  final Activity? selectedActivity;
  final ValueChanged<Activity?> onChanged;

  const ActivityDropdown({super.key, required this.selectedActivity, required this.onChanged});

  @override
  State<ActivityDropdown> createState() => _ActivityDropdownState();
}

class _ActivityDropdownState extends State<ActivityDropdown> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllActivitiesCubit>().fetchAllActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllActivitiesCubit, AllActivitiesState>(
      builder: (context, state) {
        final isLoading = state.status is AllActivitiesLoading;
        final activities = state.activities;

        if (isLoading) {
          return Text('Loading activities...');
        }

        if (activities.isEmpty) {
          return const Text('No activities available');
        }

        return AppDropdownButton<Activity>(
          items: activities,
          initialValue: widget.selectedActivity,
          hintText: "Select Activity *",
          validator: (value) => value == null ? 'required' : null,
          onChanged: widget.onChanged,
          itemLabel: (activity) => activity.name,
        );
      },
    );
  }
}
