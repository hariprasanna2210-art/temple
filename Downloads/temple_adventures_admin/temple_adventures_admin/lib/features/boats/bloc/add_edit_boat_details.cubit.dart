import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/models/boats.model.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import '../../../services/logging.dart';
import '../helpers/board_plan.helper.dart';

part 'add_edit_boat_details.cubit.freezed.dart';
part 'add_edit_boat_details.cubit.mapper.dart';

class AddEditBoatDetailsCubit extends Cubit<AddEditBoatDetailsState> {
  final BoatsRepository repository;

  AddEditBoatDetailsCubit({required this.repository})
    : super(AddEditBoatDetailsState(status: AddEditBoatDetailsStateStatus.initial()));

  Future<void> onSubmit(Boat boat) async {
    try {
      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.loading()));

      if (boat.id != null) {
        await repository.updateBoat(boat);
      } else {
        await repository.addBoat(boat);
      }

      BoardPlanHelper.updateBoardPlan(boat.date.toDateTime()!);

      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.error(e.toString())));
    }
  }

  Future<void> deleteBoat(int boatId) async {
    try {
      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.loading()));
      await repository.deleteBoat(boatId);
      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error in deleteBoat: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditBoatDetailsStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditBoatDetailsState with AddEditBoatDetailsStateMappable {
  final AddEditBoatDetailsStateStatus status;

  const AddEditBoatDetailsState({required this.status});
}

@freezed
abstract class AddEditBoatDetailsStateStatus with _$AddEditBoatDetailsStateStatus {
  const factory AddEditBoatDetailsStateStatus.initial() = AddEditBoatDetailsInitial;
  const factory AddEditBoatDetailsStateStatus.loading() = AddEditBoatDetailsLoading;
  const factory AddEditBoatDetailsStateStatus.success() = AddEditBoatDetailsSuccess;
  const factory AddEditBoatDetailsStateStatus.error(String message) = AddEditBoatDetailsError;
}
