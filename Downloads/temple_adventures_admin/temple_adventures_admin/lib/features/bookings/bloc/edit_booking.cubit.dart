import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../../../services/logging.dart';
import '../models/booking.model.dart';

part 'edit_booking.cubit.freezed.dart';
part 'edit_booking.cubit.mapper.dart';

class EditBookingCubit extends Cubit<EditBookingState> {
  final BookingsRepository repository;
  final LogsRepository logRepository;

  EditBookingCubit({required this.repository, required this.logRepository})
    : super(EditBookingState(status: EditBookingStatus.initial()));

  Future<void> onUpdate(Booking booking, [Booking? originalBooking]) async {
    try {
      emit(state.copyWith(status: EditBookingStatus.loading()));

      if (booking.id == null) {
        return;
      }
      await repository.updateBooking(booking, originalBooking);
      if (booking.cancelBooking == true) {
        await logRepository.addLog(
          actionType: ActionType.bookingDeleted,
          referenceId: booking.id,
          additionalInformation: {
            'cancellation_reason': booking.cancellationReason,
          },
        );
      } else {
        await logRepository.addLog(
          actionType: ActionType.bookingEdited,
          referenceId: booking.id,
        );
      }

      // Update board plan once after edit/cancel
      await booking.updateInBoardPlan();

      emit(state.copyWith(status: EditBookingStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: EditBookingStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class EditBookingState with EditBookingStateMappable {
  final EditBookingStatus status;

  const EditBookingState({required this.status});
}

@freezed
class EditBookingStatus with _$EditBookingStatus {
  const factory EditBookingStatus.initial() = EditBookingInitial;
  const factory EditBookingStatus.loading() = EditBookingLoading;
  const factory EditBookingStatus.success() = EditBookingSuccess;
  const factory EditBookingStatus.error(String message) = EditBookingError;
}
