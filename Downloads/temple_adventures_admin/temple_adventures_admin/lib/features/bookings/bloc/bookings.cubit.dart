import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../../services/logging.dart';
import '../models/booking.model.dart';

part 'bookings.cubit.freezed.dart';
part 'bookings.cubit.mapper.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final BookingsRepository bookingsRepository;

  BookingsCubit({required this.bookingsRepository})
    : super(BookingsState(status: BookingsStateStatus.initial(), selectedDate: DateTime.now()));

  Future<void> fetchBookings() async {
    emit(state.copyWith(status: BookingsStateStatus.loading()));
    try {
      final bookings = await bookingsRepository.fetchBookings(state.selectedDate.formatDDMMYYYY);
      emit(state.copyWith(status: BookingsStateStatus.success(bookings)));
    } catch (e, stack) {
      Log.e('Error loading bookings for date pressed', error: e, stackTrace: stack);
      emit(state.copyWith(status: BookingsStateStatus.error(e.toString())));
    }
  }

  Future<void> updateDateTime({required DateTime selectedDate, bool refreshBookings = false}) async {
    emit(state.copyWith(selectedDate: selectedDate));
    if (refreshBookings) fetchBookings();
  }
}

@immutable
@MappableClass()
class BookingsState with BookingsStateMappable {
  final BookingsStateStatus status;
  final DateTime selectedDate;

  BookingsState({required this.status, required this.selectedDate});
}

@freezed
abstract class BookingsStateStatus with _$BookingsStateStatus {
  const factory BookingsStateStatus.initial() = BookingsInitial;
  const factory BookingsStateStatus.loading() = BookingsLoading;
  const factory BookingsStateStatus.success(List<Booking> bookings) = BookingsSuccess;
  const factory BookingsStateStatus.error(String message) = BookingsError;
}
