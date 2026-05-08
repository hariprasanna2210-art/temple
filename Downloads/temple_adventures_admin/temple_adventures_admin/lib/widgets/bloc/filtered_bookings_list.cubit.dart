import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/models/boats.model.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../features/boats/repository/boats.repository.dart';
import '../../features/bookings/models/booking.model.dart';
import '../filtered_bookings_list.dart';

part 'filtered_bookings_list.cubit.mapper.dart';

class FilteredBookingsListCubit extends Cubit<FilteredBookingsListState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;

  FilteredBookingsListCubit({
    required this.bookingsRepository,
    required this.boatsRepository,
    required List<Booking> bookings,
  }) : super(
         FilteredBookingsListState(bookings: bookings),
       );

  void updateBooking(
    Booking booking,
  ) {
    List<Booking> updatedBookings = [];
    for (int i = 0; i < state.bookings.length; i++) {
      final Booking existingBooking = state.bookings[i];
      updatedBookings.add(existingBooking.id == booking.id ? booking : existingBooking);
    }

    emit(state.copyWith(bookings: updatedBookings));
  }
}

@immutable
@MappableClass()
class FilteredBookingsListState with FilteredBookingsListStateMappable {
  final List<Booking> bookings;

  const FilteredBookingsListState({
    required this.bookings,
  });

  List<Booking> filterBookings({
    required DateTime selectedDate,
    DateTime? selectedTime,
    Boat? selectedBoat,
    BookingSession? selectedSession,
  }) {
    if (bookings.isEmpty) return [];

    // Filter bookings by selected session and date
    List<Booking> filteredBookings =
        bookings.where((booking) {
          return switch (selectedSession) {
            BookingSession.theory => (booking.theoryDate ?? []).containsDateOnly(selectedDate),
            BookingSession.pool => (booking.poolDate ?? []).containsDateOnly(selectedDate),
            BookingSession.dive => (booking.diveDate ?? []).containsDateOnly(selectedDate),
            _ => true,
          };
        }).toList();

    // Filter by selected time
    if (selectedTime != null) {
      filteredBookings = List.of(
        filteredBookings.where((booking) {
          final allDates = [...?booking.theoryDate, ...?booking.poolDate, ...?booking.diveDate];
          return allDates.contains(selectedTime);
        }).toList(),
      );
    }

    // Filter by selected boat
    if (selectedBoat != null) {
      filteredBookings = filteredBookings.where((booking) => booking.boat?.id == selectedBoat.id).toList();
    }

    return filteredBookings;
  }

  Map<DateTime, int> getAvailableTimes({
    required DateTime selectedDate,
    BookingSession? selectedSession,
    Boat? selectedBoat,
  }) {
    List<Booking> filteredBooking = filterBookings(
      selectedDate: selectedDate,
      selectedSession: selectedSession,
      selectedBoat: selectedBoat,
    );

    List<DateTime> times = [];
    for (final booking in filteredBooking) {
      switch (selectedSession) {
        case BookingSession.theory:
          times.addAll(booking.theoryDate ?? []);
        case BookingSession.pool:
          times.addAll(booking.poolDate ?? []);
        case BookingSession.dive:
          times.addAll(booking.diveDate ?? []);
        case null:
          times.addAll(booking.theoryDate ?? []);
          times.addAll(booking.poolDate ?? []);
          times.addAll(booking.diveDate ?? []);
      }
    }
    times.removeWhere((date) => !date.isSameDate(selectedDate));
    times = times.toSet().toList()..sort((a, b) => a.compareTo(b));

    Map<DateTime, int> timeCount = {};

    for (final time in times) {
      timeCount[time] = 0;
      for (final booking in filteredBooking) {
        if (booking.allDates?.contains(time) ?? false) {
          timeCount[time] = booking.noOfPersons;
        }
      }
    }

    // Filter times that match the selected date
    return timeCount;
  }
}
