import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../../../../services/logging.dart';
import '../models/activity.model.dart';
import '../repository/activity.repository.dart';

part 'add_edit_activity.cubit.freezed.dart';
part 'add_edit_activity.cubit.mapper.dart';

class AddEditActivityCubit extends Cubit<AddEditActivityState> {
  final ActivityRepository repository;
  final LogsRepository logRepository;

  AddEditActivityCubit({required this.repository, required this.logRepository})
    : super(const AddEditActivityState(status: AddEditActivityStatus.initial()));

  Future<void> onSubmit(BuildContext context, Activity activity) async {
    try {
      emit(state.copyWith(status: AddEditActivityStatus.loading()));

      Activity? updatedActivity = activity;

      if (updatedActivity.id == null) {
        updatedActivity = await repository.addActivity(updatedActivity);
        if (updatedActivity?.id != null) {
          await logRepository.addLog(
            actionType: ActionType.addActivity,
            name: updatedActivity?.name,
            referenceId: updatedActivity?.id,
          );
        }
      } else {
        await repository.editActivity(updatedActivity);
        if (updatedActivity.id != null) {
          if (updatedActivity.isDeleted) {
            await logRepository.addLog(
              actionType: ActionType.deleteActivity,
              name: updatedActivity.name,
              referenceId: updatedActivity.id,
            );
          } else {
            await logRepository.addLog(
              actionType: ActionType.editActivity,
              name: updatedActivity.name,
              referenceId: updatedActivity.id,
            );
          }
        }
      }

      emit(state.copyWith(status: AddEditActivityStatus.success()));
    } catch (e, stack) {
      Log.e('Error handling  activity  pressed', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditActivityError(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditActivityState with AddEditActivityStateMappable {
  final AddEditActivityStatus status;

  const AddEditActivityState({required this.status});
}

@freezed
class AddEditActivityStatus with _$AddEditActivityStatus {
  const factory AddEditActivityStatus.initial() = AddEditActivityInitial;
  const factory AddEditActivityStatus.success() = AddEditActivitySuccess;
  const factory AddEditActivityStatus.loading() = AddEditActivityLoading;
  const factory AddEditActivityStatus.error(String message) = AddEditActivityError;
}
