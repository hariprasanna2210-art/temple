import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Cubit;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/models/payment.model.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';

import '../../../services/logging.dart';

part 'payment_details.cubit.freezed.dart';

class PaymentDetailsCubit extends Cubit<PaymentDetailsState> {
  final BookingsRepository repository;

  PaymentDetailsCubit({required this.repository}) : super(const PaymentDetailsState.initial());

  Future<void> deletePayment(int paymentId) async {
    emit(const PaymentDetailsState.loading());

    try {
      await repository.deletePayment(paymentId);
      emit(const PaymentDetailsState.success());
    } catch (e, stack) {
      Log.e('Error deleting payment', error: e, stackTrace: stack);
      emit(const PaymentDetailsState.error('Failed to delete payment'));
    }
  }

  Future<void> onSubmit(
    BuildContext context, {
    int? bookingId,
    required bool createBooking,
    Booking? booking,
    required Payment payment,
  }) async {
    try {
      emit(const PaymentDetailsState.loading());

      // If createBooking is true it means customer is paying initial deposit while booking a course.

      if (createBooking && booking != null) {
        bookingId = await repository.addBooking(booking);
        // Update board plan once after booking is created
        await booking.updateInBoardPlan();
      }

      if (bookingId == null) {
        Log.e('Invalid case: booking id is null');
        return;
      }

      Log.i('Booking created successfully');

      // If bookingId is not null and payment.id is null then adding  payment
      if (payment.id == null) {
        await repository.addPayment(payment, bookingId);
      } else {
        await repository.updatePayment(payment, bookingId);
      }

      emit(const PaymentDetailsState.success());
    } catch (e, stack) {
      Log.e('Error creating booking / adding payment / editing payment', error: e, stackTrace: stack);
      emit(const PaymentDetailsState.error('Error creating booking / adding payment / editing payment'));
    }
  }
}

@freezed
class PaymentDetailsState with _$PaymentDetailsState {
  const factory PaymentDetailsState.initial() = PaymentDetailsInitial;
  const factory PaymentDetailsState.loading() = PaymentDetailsLoading;
  const factory PaymentDetailsState.success() = PaymentDetailsSuccess;
  const factory PaymentDetailsState.error(String message) = PaymentDetailsError;
}
