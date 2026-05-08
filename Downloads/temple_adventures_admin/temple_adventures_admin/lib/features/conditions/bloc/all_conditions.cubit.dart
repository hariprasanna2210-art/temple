import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../main.dart';
import '../../../services/logging.dart';
import '../../user/bloc/user.cubit.dart';
import '../model/surface_conditions.model.dart';
import '../model/water_conditions.model.dart';
import '../repository/conditions.repository.dart';
part 'all_conditions.cubit.freezed.dart';
part 'all_conditions.cubit.mapper.dart';

class AllConditionsCubit extends Cubit<AllConditionState> {
  final ConditionsRepository conditionRepository;

  AllConditionsCubit({
    required this.conditionRepository,
  }) : super(
         AllConditionState(
           status: const AllConditionStatus.initial(),
           reefs: const ['Shallow site area', 'Northern Rocks area', 'Wall area'],
           selectedDate: DateTime.now(),
           selectedReef: 'Shallow site area',
           surfaceConditions: [],
           waterConditions: [],
         ),
       );
  final List<int> _deletedWaterConditionIds = [];

  List<int> get deletedWaterConditionIds => _deletedWaterConditionIds;

  Future<void> fetchSurfaceCondition(DateTime date) async {
    try {
      emit(state.copyWith(status: const AllConditionStatus.loading()));
      final conditions = await conditionRepository.fetchSurfaceCondition(date);
      final surfaceData = conditions.isEmpty ? defaultSurfaceConditions(date) : conditions;
      emit(state.copyWith(status: const AllConditionStatus.loaded(), surfaceConditions: surfaceData));
    } catch (e, stack) {
      emit(state.copyWith(status: AllConditionStatus.error('No conditions found: ${e.toString()}')));
      Log.e('Error fetching conditions', error: e, stackTrace: stack);
    }
  }

  Future<void> fetchConditions(DateTime date) async {
    try {
      emit(state.copyWith(status: const AllConditionStatus.loading()));
      final conditions = await conditionRepository.fetchSurfaceCondition(date);
      if (conditions.isEmpty) {
        emit(state.copyWith(status: AllConditionStatus.loaded(), surfaceConditions: []));
        return;
      }
      emit(state.copyWith(status: const AllConditionStatus.loaded(), surfaceConditions: conditions));
    } catch (e, stack) {
      emit(state.copyWith(status: AllConditionStatus.error('No conditions found: ${e.toString()}')));
      Log.e('Error fetching conditions', error: e, stackTrace: stack);
    }
  }

  void updateSurfaceConditionValue({
    required String reefName,
    double? temp,
    double? speed,
    double? currents,
    double? swell,
  }) {
    final updatedList =
        state.surfaceConditions.map((condition) {
          if (condition.reefName == reefName) {
            return condition.copyWith(
              temp: temp ?? condition.temp,
              speed: speed ?? condition.speed,
              currents: currents ?? condition.currents,
              swell: swell ?? condition.swell,
              updatedAt: DateTime.now(),
            );
          }
          return condition;
        }).toList();

    emit(state.copyWith(surfaceConditions: updatedList));
  }

  void clearDeletedWaterConditionIds() {
    _deletedWaterConditionIds.clear();
  }

  void updateWaterConditionAtIndex({
    required int index,
    required WaterConditions updatedCondition,
  }) {
    final updatedList = List<WaterConditions>.from(state.waterConditions);
    updatedList[index] = updatedCondition;

    emit(state.copyWith(waterConditions: updatedList));
  }

  List<SurfaceConditions> defaultSurfaceConditions(DateTime date) {
    final reefs = state.reefs;
    BuildContext? context = navigatorKey.currentContext;
    final currentUser = context?.read<UserCubit>().state.currentUser;

    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final employeeName = currentUser;

    final conditions = List.generate(
      reefs.length,
      (index) {
        final conditions = SurfaceConditions(
          reefName: reefs[index],
          temp: 20,
          speed: 0,
          currents: 0,
          swell: 0,
          updatedAt: DateTime.now(),
          updatedBy: employeeName,
          date: date,
        );
        return conditions;
      },
    );
    return conditions;
  }

  Future<void> fetchWaterCondition(DateTime date) async {
    try {
      emit(state.copyWith(status: const AllConditionStatus.loading()));
      final conditions = await conditionRepository.fetchWaterCondition(date);
      emit(state.copyWith(status: const AllConditionStatus.loaded(), waterConditions: conditions));
    } catch (e, stack) {
      emit(state.copyWith(status: AllConditionStatus.error('No conditions found: ${e.toString()}')));
      Log.e('Error fetching conditions', error: e, stackTrace: stack);
    }
  }

  void deleteWaterConditionByIndex(int index) {
    final condition = state.waterConditions[index];
    if (condition.id != null) {
      _deletedWaterConditionIds.add(condition.id!);
    }
    final updated = List.of(state.waterConditions)..removeAt(index);

    emit(state.copyWith(waterConditions: updated, status: const AllConditionStatus.loaded()));
  }

  void clearAllConditions() {
    emit(
      state.copyWith(
        surfaceConditions: [],
        waterConditions: [],
        status: const AllConditionStatus.initial(),
      ),
    );
  }

  void resetToCurrentDate() {
    final now = DateTime.now();
    emit(state.copyWith(selectedDate: now));
    clearAllConditions();
    fetchConditions(now);
    fetchWaterCondition(now);
  }

  void updateSelectedDate(DateTime newDate) {
    emit(state.copyWith(selectedDate: newDate));
    fetchConditions(newDate);
    fetchWaterCondition(newDate);
  }

  List<WaterConditions> get filteredWaterConditions {
    return state.waterConditions.where((c) => c.reef == state.selectedReef).toList();
  }

  List<SurfaceConditions> get filteredSurfaceConditions {
    return state.surfaceConditions.where((c) => c.reefName == state.selectedReef).toList();
  }

  void addWaterConditions(WaterConditions updatedCondition) {
    final conditions = List.of(state.waterConditions);
    conditions.add(updatedCondition);
    emit(state.copyWith(waterConditions: conditions, status: AllConditionStatus.loaded()));
  }

  void onReefSelected(String reefName) {
    emit(state.copyWith(status: AllConditionLoaded(), selectedReef: reefName));
  }
}

@immutable
@MappableClass()
class AllConditionState with AllConditionStateMappable {
  final AllConditionStatus status;
  final List<String> reefs;
  final List<SurfaceConditions> surfaceConditions;
  final List<WaterConditions> waterConditions;
  final DateTime selectedDate;
  final String selectedReef;

  const AllConditionState({
    required this.status,
    this.reefs = const [],
    required this.surfaceConditions,
    required this.waterConditions,
    required this.selectedDate,
    required this.selectedReef,
  });
}

@freezed
class AllConditionStatus with _$AllConditionStatus {
  const factory AllConditionStatus.initial() = AllConditionInitial;

  const factory AllConditionStatus.success(String message) = AllConditionSuccess;
  const factory AllConditionStatus.loading() = AllConditionLoading;
  const factory AllConditionStatus.loaded() = AllConditionLoaded;
  const factory AllConditionStatus.error(String message) = AllConditionError;
}
