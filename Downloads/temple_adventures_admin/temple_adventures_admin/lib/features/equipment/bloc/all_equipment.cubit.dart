import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/equipment/model/equipment_category.model.dart';
import 'package:temple_adventures_admin/features/user/models/user.model.dart';

import '../../../services/logging.dart';
import '../model/enriched_equipment_logs.model.dart';
import '../model/equipment_item.model.dart';
import '../respository/equipment.repository.dart';

part 'all_equipment.cubit.freezed.dart';
part 'all_equipment.cubit.mapper.dart';

class AllEquipmentCubit extends Cubit<AllEquipmentState> {
  final EquipmentRepository repository;

  AllEquipmentCubit({required this.repository})
    : super(
        const AllEquipmentState(
          status: AllEquipmentStatus.initial(),
          categories: [],
          equipmentItems: [],
          selectedItems: [],
          logs: [],
          employees: [],
        ),
      );

  Future<void> fetchCategories() async {
    try {
      emit(state.copyWith(status: AllEquipmentStatus.loading()));
      final categories = await repository.fetchEquipmentCategories();
      emit(state.copyWith(status: const AllEquipmentStatus.loaded(), categories: categories));
    } catch (e, stack) {
      emit(state.copyWith(status: AllEquipmentStatus.error('No category items found: ${e.toString()}')));
      Log.e('Error fetching category items', error: e, stackTrace: stack);
    }
  }

  void resetEquipmentItemSelection() {
    emit(state.copyWith(selectedItems: []));
  }

  Future<void> fetchEquipmentItems() async {
    try {
      emit(state.copyWith(status: AllEquipmentStatus.loading()));
      final equipmentItems = await repository.fetchEquipmentItems();
      emit(state.copyWith(status: const AllEquipmentStatus.loaded(), equipmentItems: equipmentItems));
    } catch (e, stack) {
      emit(state.copyWith(status: AllEquipmentStatus.error('No equipment items found: ${e.toString()}')));
      Log.e('Error fetching equipment items', error: e, stackTrace: stack);
    }
  }

  void toggleEquipmentItemSelection(EquipmentItem equipmentItem) {
    final updatedList = List<EquipmentItem>.from(state.selectedItems);
    if (updatedList.contains(equipmentItem)) {
      updatedList.remove(equipmentItem);
    } else {
      updatedList.add(equipmentItem);
    }
    emit(state.copyWith(selectedItems: updatedList));
  }

  Future<void> upsertCategory(EquipmentCategory updatedCategory) async {
    try {
      final updatedList = List.of(state.categories);
      final index = updatedList.indexWhere((category) => category.id == updatedCategory.id);
      if (index != -1) {
        updatedList[index] = updatedCategory;
      } else {
        updatedList.add(updatedCategory);
      }
      emit(state.copyWith(categories: updatedList));
    } catch (e, stack) {
      Log.e('Error in addOrEditCategory', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllEquipmentStatus.error(e.toString())));
    }
  }

  Future<void> upsertEquipmentItem(EquipmentItem updatedEquipmentItem) async {
    try {
      final updatedList = List.of(state.equipmentItems);
      final index = updatedList.indexWhere((equipment) => equipment.id == updatedEquipmentItem.id);
      if (index != -1) {
        updatedList[index] = updatedEquipmentItem;
      } else {
        updatedList.add(updatedEquipmentItem);
      }
      emit(state.copyWith(equipmentItems: updatedList));
    } catch (e, stack) {
      Log.e('Error in addOrEditEquipment', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllEquipmentStatus.error(e.toString())));
    }
  }

  void deleteCategoryFromList(int categoryId) {
    final updatedCategories = state.categories.where((cat) => cat.id != categoryId).toList();
    emit(state.copyWith(categories: updatedCategories));
  }

  void deleteEquipmentItemFromList(int equipmentItemId) async {
    final updatedEquipmentItems = state.equipmentItems.where((equip) => equip.id != equipmentItemId).toList();
    emit(state.copyWith(equipmentItems: updatedEquipmentItems));
  }
}

@immutable
@MappableClass()
class AllEquipmentState with AllEquipmentStateMappable {
  final AllEquipmentStatus status;
  final List<EquipmentCategory> categories;
  final List<EquipmentItem> equipmentItems;
  final List<EquipmentItem> selectedItems;
  final List<EnrichedEquipmentLogs> logs;
  final List<User> employees;

  const AllEquipmentState({
    required this.status,
    required this.categories,
    required this.equipmentItems,
    required this.selectedItems,
    required this.logs,
    required this.employees,
  });
}

@freezed
class AllEquipmentStatus with _$AllEquipmentStatus {
  const factory AllEquipmentStatus.initial() = AllEquipmentInitial;
  const factory AllEquipmentStatus.loading() = AllEquipmentLoading;
  const factory AllEquipmentStatus.loaded() = AllEquipmentLoaded;
  const factory AllEquipmentStatus.success(String message) = AllEquipmentSuccess;
  const factory AllEquipmentStatus.error(String message) = AllEquipmentError;
}
