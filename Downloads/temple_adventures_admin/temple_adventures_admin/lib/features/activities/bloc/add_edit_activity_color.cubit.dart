import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/activities/bloc/all_activity_colors.cubit.dart';
import '../../../services/logging.dart';
import '../models/activity_color.model.dart';
import '../repository/activity.repository.dart';

part 'add_edit_activity_color.cubit.freezed.dart';
part 'add_edit_activity_color.cubit.mapper.dart';

class AddEditActivityColorCubit extends Cubit<AddEditActivityColorState> {
  final ActivityRepository repository;

  AddEditActivityColorCubit({required this.repository})
    : super(
        AddEditActivityColorState(
          selectedColor: Colors.blue,
          status: AddEditActivityColorStatus.initial(),
        ),
      );

  void updateColor(Color? color) {
    if (color == null) return;
    emit(state.copyWith(selectedColor: color));
  }

  Future<void> onSubmit(BuildContext context, {required ActivityColor activityColor}) async {
    try {
      emit(state.copyWith(status: AddEditActivityColorLoading()));

      ActivityColor? updatedActivityColor = activityColor;

      if (updatedActivityColor.id == null) {
        updatedActivityColor = await repository.addActivityColor(updatedActivityColor);
      } else {
        await repository.editActivityColor(updatedActivityColor);
      }

      if (updatedActivityColor != null && context.mounted) {
        context.read<AllActivityColorsCubit>().replaceActivityColor(updatedActivityColor);
      }

      emit(state.copyWith(status: AddEditActivityColorSuccess()));
    } catch (e, stack) {
      Log.e('Error handling activity color pressed', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditActivityColorError(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditActivityColorState with AddEditActivityColorStateMappable {
  final Color selectedColor;
  final AddEditActivityColorStatus status;

  const AddEditActivityColorState({required this.selectedColor, required this.status});
}

@freezed
class AddEditActivityColorStatus with _$AddEditActivityColorStatus {
  const factory AddEditActivityColorStatus.initial() = AddEditActivityColorInitial;
  const factory AddEditActivityColorStatus.loading() = AddEditActivityColorLoading;
  const factory AddEditActivityColorStatus.success() = AddEditActivityColorSuccess;
  const factory AddEditActivityColorStatus.error(String message) = AddEditActivityColorError;
}
