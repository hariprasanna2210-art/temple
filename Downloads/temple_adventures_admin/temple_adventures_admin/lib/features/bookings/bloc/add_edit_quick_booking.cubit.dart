import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import '../../../services/logging.dart';
import '../models/booking.model.dart';

part 'add_edit_quick_booking.cubit.freezed.dart';
part 'add_edit_quick_booking.cubit.mapper.dart';

class AddEditQuickBookingCubit extends Cubit<AddEditQuickBookingState> {
  final BookingsRepository repository;
  final LogsRepository logRepository;

  AddEditQuickBookingCubit({required this.repository, required this.logRepository})
    : super(AddEditQuickBookingState(status: AddEditQuickBookingStatus.initial()));

  Future<void> onSubmit(Booking booking, [Booking? originalBooking]) async {
    try {
      emit(state.copyWith(status: AddEditQuickBookingStatus.loading()));
      if (booking.id == null) {
        // Adding a new booking
        final int? updatedBookingId = await repository.addBooking(booking);
        if (updatedBookingId != null) {
          await logRepository.addLog(
            actionType: ActionType.quickBookingCreated,
            referenceId: updatedBookingId,
            additionalInformation: {
              'created_by_id': booking.createdBy.id,
            },
          );
        }
      } else {
        // Updating existing booking
        await repository.updateBooking(booking, originalBooking);

        if (booking.cancelBooking == true) {
          await logRepository.addLog(
            actionType: ActionType.quickBookingDeleted,
            referenceId: booking.id,
            additionalInformation: {
              'cancellation_reason': booking.cancellationReason,
            },
          );
        } else {
          await logRepository.addLog(
            actionType: ActionType.quickBookingEdited,
            referenceId: booking.id,
          );
        }
      }

      // Update board plan once after create/edit/cancel
      await booking.updateInBoardPlan();

      emit(state.copyWith(status: AddEditQuickBookingStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditQuickBookingStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class AddEditQuickBookingState with AddEditQuickBookingStateMappable {
  final AddEditQuickBookingStatus status;

  const AddEditQuickBookingState({required this.status});
}

@freezed
class AddEditQuickBookingStatus with _$AddEditQuickBookingStatus {
  const factory AddEditQuickBookingStatus.initial() = AddEditQuickBookingInitial;
  const factory AddEditQuickBookingStatus.loading() = AddEditQuickBookingLoading;
  const factory AddEditQuickBookingStatus.success() = AddEditQuickBookingSuccess;
  const factory AddEditQuickBookingStatus.error(String message) = AddEditQuickBookingError;
}
