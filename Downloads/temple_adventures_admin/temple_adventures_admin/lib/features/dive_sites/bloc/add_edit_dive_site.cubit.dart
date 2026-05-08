import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../services/logging.dart';
import '../model/dive_site.model.dart';
import '../repository/dive_site.repository.dart';
import 'dive_sites.cubit.dart';

part 'add_edit_dive_site.cubit.freezed.dart';

part 'add_edit_dive_site.cubit.mapper.dart';

class AddEditDiveSiteCubit extends Cubit<AddEditDiveSiteState> {
  final DiveSiteRepository repository;

  AddEditDiveSiteCubit({
    required this.repository,
  }) : super(AddEditDiveSiteState(status: AddEditDiveSiteStatus.initial()));

  Future<void> onDiveSiteSubmit(BuildContext context, DiveSite diveSite) async {
    try {
      emit(state.copyWith(status: AddEditDiveSiteLoading()));
      DiveSite? updatedDiveSite = diveSite;

      if (updatedDiveSite.id == null) {
        updatedDiveSite = await repository.addDiveSite(updatedDiveSite);
      } else {
        updatedDiveSite = await repository.editDiveSite(diveSite);
      }

      if (updatedDiveSite == null) {
        emit(state.copyWith(status: AddEditDiveSiteStatus.error('Failed to save dive site')));
        return;
      }
      emit(state.copyWith(status: AddEditDiveSiteStatus.success(true)));
    } catch (e, stack) {
      Log.e('Error in onCategorySubmit', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditDiveSiteStatus.error(e.toString())));
    }
  }

  Future<void> deleteDiveSite(BuildContext context, int diveSiteId) async {
    try {
      emit(state.copyWith(status: AddEditDiveSiteLoading()));
      await repository.deleteDiveSite(diveSiteId);
      if (context.mounted) {
        context.read<DiveSiteCubit>().deleteDiveSite(diveSiteId);
      }
      emit(state.copyWith(status: AddEditDiveSiteSuccess(true)));
    } catch (e, stack) {
      Log.e('Error in onDeleteCategory', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditDiveSiteStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditDiveSiteState with AddEditDiveSiteStateMappable {
  final AddEditDiveSiteStatus status;

  const AddEditDiveSiteState({required this.status});
}

@freezed
class AddEditDiveSiteStatus with _$AddEditDiveSiteStatus {
  const factory AddEditDiveSiteStatus.initial() = AddEditDiveSiteInitial;

  const factory AddEditDiveSiteStatus.success(bool shouldPop) = AddEditDiveSiteSuccess;

  const factory AddEditDiveSiteStatus.deleteLoading() = AddEditDiveSiteDeleteLoading;

  const factory AddEditDiveSiteStatus.uploadLoading() = AddEditDiveSiteUploading;

  const factory AddEditDiveSiteStatus.loading() = AddEditDiveSiteLoading;

  const factory AddEditDiveSiteStatus.error(String message) = AddEditDiveSiteError;
}
