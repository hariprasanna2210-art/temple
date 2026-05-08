import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/checklists/models/template.model.dart';
import 'package:temple_adventures_admin/features/checklists/repository/checklist.repository.dart';
import '../../../services/logging.dart';

part 'add_edit_template.cubit.freezed.dart';
part 'add_edit_template.cubit.mapper.dart';

class AddEditTemplateCubit extends Cubit<AddEditTemplateState> {
  final ChecklistRepository repository;

  AddEditTemplateCubit({required this.repository})
    : super(AddEditTemplateState(status: AddEditTemplateStateStatus.initial()));

  Future<void> onSubmit(Template template) async {
    try {
      emit(state.copyWith(status: AddEditTemplateStateStatus.loading()));

      if (template.id != null) {
        await repository.updateTemplate(template);
      } else {
        await repository.addTemplate(template);
      }
      emit(state.copyWith(status: AddEditTemplateStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditTemplateStateStatus.error(e.toString())));
    }
  }

  Future<void> deleteTemplate(int templateId) async {
    try {
      emit(state.copyWith(status: AddEditTemplateStateStatus.loading()));
      await repository.deleteTemplate(templateId);
      emit(state.copyWith(status: AddEditTemplateStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in deleteTemplate: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditTemplateStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditTemplateState with AddEditTemplateStateMappable {
  final AddEditTemplateStateStatus status;

  const AddEditTemplateState({required this.status});
}

@freezed
abstract class AddEditTemplateStateStatus with _$AddEditTemplateStateStatus {
  const factory AddEditTemplateStateStatus.initial() = AddEditTemplateInitial;
  const factory AddEditTemplateStateStatus.loading() = AddEditTemplateLoading;
  const factory AddEditTemplateStateStatus.success() = AddEditTemplateSuccess;
  const factory AddEditTemplateStateStatus.error(String message) = AddEditTemplateError;
}
