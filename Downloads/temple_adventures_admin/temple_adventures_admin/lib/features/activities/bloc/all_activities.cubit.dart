import 'dart:async';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../models/activity.model.dart';
import '../repository/activity.repository.dart';

part 'all_activities.cubit.freezed.dart';
part 'all_activities.cubit.mapper.dart';

class AllActivitiesCubit extends Cubit<AllActivitiesState> {
  final ActivityRepository repository;

  AllActivitiesCubit({required this.repository})
    : super(const AllActivitiesState(status: AllActivitiesStatus.initial(), activities: []));

  /// Fetch all activities if not already loaded
  Future<void> fetchAllActivities() async {
    try {
      emit(state.copyWith(status: AllActivitiesStatus.loading(), activities: state.activities));

      final activities = await repository.fetchAllActivities();

      emit(state.copyWith(status: AllActivitiesStatus.loaded(), activities: activities));
    } catch (e, s) {
      Log.e('Error fetching activities: $e', error: e, stackTrace: s);
      emit(
        state.copyWith(
          status: AllActivitiesStatus.error('No Activities found: ${e.toString()}'),
          activities: state.activities,
        ),
      );
    }
  }
}

@immutable
@MappableClass()
class AllActivitiesState with AllActivitiesStateMappable {
  final AllActivitiesStatus status;
  final List<Activity> activities;

  const AllActivitiesState({required this.status, required this.activities});
}

@freezed
class AllActivitiesStatus with _$AllActivitiesStatus {
  const factory AllActivitiesStatus.initial() = AllActivitiesInitial;
  const factory AllActivitiesStatus.loading() = AllActivitiesLoading;
  const factory AllActivitiesStatus.loaded() = AllActivitiesLoaded;
  const factory AllActivitiesStatus.error(String message) = AllActivitiesStateError;
}
