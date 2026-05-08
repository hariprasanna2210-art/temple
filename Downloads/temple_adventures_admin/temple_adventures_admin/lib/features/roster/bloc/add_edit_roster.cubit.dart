import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/logging.dart';
import '../models/roster.model.dart';
import '../repository/roster.repository.dart';

part 'add_edit_roster.cubit.freezed.dart';
part 'add_edit_roster.cubit.mapper.dart';

class AddEditRosterCubit extends Cubit<AddEditRosterState> {
  final RosterRepository repository;

  AddEditRosterCubit({required this.repository})
    : super(AddEditRosterState(status: AddEditRosterStateStatus.initial()));

  Future<void> onSubmit({
    required Roster roster,
  }) async {
    try {
      emit(state.copyWith(status: AddEditRosterStateStatus.loading()));
      await repository.addUpdateRoster(roster: roster);
      emit(state.copyWith(status: AddEditRosterStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditRosterStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditRosterState with AddEditRosterStateMappable {
  final AddEditRosterStateStatus status;

  const AddEditRosterState({required this.status});
}

@freezed
abstract class AddEditRosterStateStatus with _$AddEditRosterStateStatus {
  const factory AddEditRosterStateStatus.initial() = AddEditRosterInitial;
  const factory AddEditRosterStateStatus.loading() = AddEditRosterLoading;
  const factory AddEditRosterStateStatus.success() = AddEditRosterSuccess;
  const factory AddEditRosterStateStatus.error(String message) = AddEditRosterError;
}
