import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/checklists/models/template.model.dart';
import 'package:temple_adventures_admin/features/checklists/repository/checklist.repository.dart';
import '../../../services/logging.dart';

part 'all_templates.cubit.freezed.dart';
part 'all_templates.cubit.mapper.dart';

class AllTemplatesCubit extends Cubit<AllTemplatesState> {
  final ChecklistRepository repository;

  AllTemplatesCubit({required this.repository})
    : super(AllTemplatesState(status: AllTemplatesStateStatus.initial(), selectedTemplates: []));

  Future<void> fetchTemplates() async {
    emit(state.copyWith(status: AllTemplatesStateStatus.loading()));
    try {
      List<Template>? templates = await repository.fetchTemplates();
      fetchTemplatesFromPrefs();
      emit(state.copyWith(status: AllTemplatesStateStatus.loaded(templates)));
    } catch (e, stack) {
      Log.e('Error loading templates', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllTemplatesStateStatus.error(e.toString())));
    }
  }

  Future<void> fetchTemplatesFromPrefs() async {
    emit(state.copyWith(status: AllTemplatesStateStatus.loading()));
    try {
      List<Template> templates = await repository.getTemplatesFromPrefs();
      emit(state.copyWith(status: const AllTemplatesStateStatus.success(), selectedTemplates: templates));
    } catch (e, stack) {
      Log.e('Error loading templates', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllTemplatesStateStatus.error(e.toString())));
    }
  }

  Future<void> addCheckListToHome(int templateId) async {
    emit(state.copyWith(status: AllTemplatesStateStatus.loading()));
    try {
      await repository.addChecklistToHome(templateId);

      await fetchTemplatesFromPrefs();

      emit(state.copyWith(status: AllTemplatesStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error adding checklist', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllTemplatesStateStatus.error(e.toString())));
    }
  }

  Future<void> deleteCheckListFromHome(int templateId) async {
    emit(state.copyWith(status: AllTemplatesStateStatus.loading()));
    try {
      await repository.deleteChecklistToHome(templateId);

      await fetchTemplatesFromPrefs();

      emit(state.copyWith(status: AllTemplatesStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error deleting checklist', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllTemplatesStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AllTemplatesState with AllTemplatesStateMappable {
  final AllTemplatesStateStatus status;
  final List<Template> selectedTemplates;

  const AllTemplatesState({required this.status, required this.selectedTemplates});
}

@freezed
abstract class AllTemplatesStateStatus with _$AllTemplatesStateStatus {
  const factory AllTemplatesStateStatus.initial() = AllTemplatesInitial;
  const factory AllTemplatesStateStatus.loading() = AllTemplatesLoading;
  const factory AllTemplatesStateStatus.success() = AllTemplatessuccess;
  const factory AllTemplatesStateStatus.loaded(List<Template> templates) = AllTemplatesLoaded;
  const factory AllTemplatesStateStatus.error(String message) = AllTemplatesError;
}
