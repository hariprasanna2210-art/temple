import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/conditions/repository/conditions.repository.dart';

import '../../../services/logging.dart';
import '../model/surface_conditions.model.dart';
import '../model/water_conditions.model.dart';
import 'all_conditions.cubit.dart';

part 'add_edit_condition.cubit.freezed.dart';
part 'add_edit_condition.cubit.mapper.dart';

class AddEditConditionCubit extends Cubit<AddEditConditionState> {
  final ConditionsRepository conditionRepository;

  AddEditConditionCubit({
    required this.conditionRepository,
  }) : super(const AddEditConditionState(status: AddEditConditionStatus.initial()));

  Future<void> onConditionSubmitAll(
    BuildContext context,
    List<SurfaceConditions> surfaceConditions,
    List<WaterConditions> waterConditions,
  ) async {
    try {
      emit(state.copyWith(status: AddEditConditionLoading()));
      final allCubit = context.read<AllConditionsCubit>();

      for (final surface in surfaceConditions) {
        if (surface.id == null) {
          await conditionRepository.addSurfaceCondition(surface);
        } else {
          await conditionRepository.editSurfaceCondition(surface);
        }
      }

      for (final water in waterConditions) {
        if (water.id == null) {
          await conditionRepository.addWaterCondition(water);
        } else {
          await conditionRepository.editWaterCondition(water);
        }
      }
      for (final id in allCubit.deletedWaterConditionIds) {
        await conditionRepository.deleteWaterCondition(id);
      }
      allCubit.clearDeletedWaterConditionIds();

      emit(state.copyWith(status: AddEditConditionStatus.success(true)));
    } catch (e, stack) {
      emit(state.copyWith(status: AddEditConditionStatus.error(e.toString())));
      Log.e('Error in AddEditConditionCubit', error: e, stackTrace: stack);
    }
  }
}

@immutable
@MappableClass()
class AddEditConditionState with AddEditConditionStateMappable {
  final AddEditConditionStatus status;

  const AddEditConditionState({required this.status});
}

@freezed
class AddEditConditionStatus with _$AddEditConditionStatus {
  const factory AddEditConditionStatus.initial() = AddEditConditionInitial;
  const factory AddEditConditionStatus.success(bool shouldPop) = AddEditConditionSuccess;
  const factory AddEditConditionStatus.loading() = AddEditConditionLoading;
  const factory AddEditConditionStatus.error(String message) = AddEditConditionError;
}
