import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../model/equipment_category.model.dart';
import '../model/equipment_item.model.dart';
import '../respository/equipment.repository.dart';
import 'all_equipment.cubit.dart';

part 'add_edit_equipment_item.cubit.freezed.dart';
part 'add_edit_equipment_item.cubit.mapper.dart';

class AddEditEquipmentItemCubit extends Cubit<AddEditEquipmentItemState> {
  final EquipmentRepository equipmentRepository;

  AddEditEquipmentItemCubit({
    required this.equipmentRepository,
  }) : super(const AddEditEquipmentItemState(status: AddEditEquipmentItemStatus.initial()));

  /// Handles equipment item creation or update and updates the global state on success
  Future<void> onEquipmentItemSubmit(BuildContext context, EquipmentItem equipmentItem) async {
    try {
      emit(state.copyWith(status: AddEditEquipmentItemLoading()));
      EquipmentItem? updatedEquipmentItem = equipmentItem;
      if (updatedEquipmentItem.id == null) {
        updatedEquipmentItem = await equipmentRepository.addNewEquipment(updatedEquipmentItem);
      } else {
        updatedEquipmentItem = await equipmentRepository.editEquipment(updatedEquipmentItem);
      }
      if (updatedEquipmentItem == null) {
        emit(state.copyWith(status: const AddEditEquipmentItemStatus.error("Failed to save equipment item")));
        return;
      }
      emit(state.copyWith(status: AddEditEquipmentItemStatus.success(true)));

      if (context.mounted) {
        context.read<AllEquipmentCubit>().upsertEquipmentItem(updatedEquipmentItem);
      }
    } catch (e, stack) {
      Log.e('Error in addEditEquipmentItemCubit', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditEquipmentItemStatus.error(e.toString())));
    }
  }

  ///  Handles equipment category creation or update and updates the global state on success
  Future<void> onCategorySubmit(BuildContext context, EquipmentCategory category) async {
    try {
      emit(state.copyWith(status: AddEditEquipmentItemLoading()));

      EquipmentCategory? updatedCategory = category;
      if (updatedCategory.id == null) {
        updatedCategory = await equipmentRepository.addCategory(updatedCategory);
      } else {
        updatedCategory = await equipmentRepository.editCategory(updatedCategory);
      }

      if (updatedCategory == null) {
        emit(
          state.copyWith(
            status: const AddEditEquipmentItemStatus.error("Failed to save category"),
          ),
        );
        return;
      }

      if (context.mounted) {
        context.read<AllEquipmentCubit>().upsertCategory(updatedCategory);
      }
      emit(state.copyWith(status: AddEditEquipmentItemStatus.success(false)));
    } catch (e, stack) {
      Log.e('Error in onCategorySubmit', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditEquipmentItemStatus.error(e.toString())));
    }
  }

  Future<void> deleteCategory(BuildContext context, int categoryId) async {
    try {
      emit(state.copyWith(status: AddEditEquipmentItemDeleteLoading()));
      await equipmentRepository.deleteCategory(categoryId);
      if (context.mounted) {
        context.read<AllEquipmentCubit>().deleteCategoryFromList(categoryId);
      }
      emit(state.copyWith(status: AddEditEquipmentItemSuccess(false)));
    } catch (e, stack) {
      Log.e('Error in onDeleteCategory', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditEquipmentItemStatus.error(e.toString())));
    }
  }

  Future<void> deleteEquipmentItem(BuildContext context, int equipmentId) async {
    try {
      emit(state.copyWith(status: AddEditEquipmentItemDeleteLoading()));
      await equipmentRepository.deleteEquipment(equipmentId);
      if (context.mounted) {
        context.read<AllEquipmentCubit>().deleteEquipmentItemFromList(equipmentId);
      }
      emit(state.copyWith(status: AddEditEquipmentItemSuccess(true)));
    } catch (e, stack) {
      Log.e('Error in onDeleteCategory', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditEquipmentItemStatus.error(e.toString())));
    }
  }

  Future<String?> uploadEquipmentImage(File? imageFile) async {
    try {
      if (imageFile == null) {
        throw Exception('The image file is not found ');
      }
      emit(state.copyWith(status: AddEditEquipmentItemStatus.uploadLoading()));
      final url = await equipmentRepository.uploadEquipmentImage(imageFile);
      if (url == null) throw Exception('Upload failed');
      emit(state.copyWith(status: AddEditEquipmentItemStatus.success(false)));
      return url;
    } catch (e, stack) {
      emit(
        state.copyWith(
          status: AddEditEquipmentItemStatus.error('Error occurred in uploading the image ${e.toString()}'),
        ),
      );
      Log.e('Error deleting category', error: e, stackTrace: stack);
      return null;
    }
  }
}

@immutable
@MappableClass()
class AddEditEquipmentItemState with AddEditEquipmentItemStateMappable {
  final AddEditEquipmentItemStatus status;
  const AddEditEquipmentItemState({required this.status});
}

@freezed
class AddEditEquipmentItemStatus with _$AddEditEquipmentItemStatus {
  const factory AddEditEquipmentItemStatus.initial() = AddEditEquipmentItemInitial;
  const factory AddEditEquipmentItemStatus.success(bool shouldPop) = AddEditEquipmentItemSuccess;
  const factory AddEditEquipmentItemStatus.deleteLoading() = AddEditEquipmentItemDeleteLoading;
  const factory AddEditEquipmentItemStatus.uploadLoading() = AddEditEquipmentItemUploadLoading;
  const factory AddEditEquipmentItemStatus.loading() = AddEditEquipmentItemLoading;
  const factory AddEditEquipmentItemStatus.error(String message) = AddEditEquipmentItemError;
}
