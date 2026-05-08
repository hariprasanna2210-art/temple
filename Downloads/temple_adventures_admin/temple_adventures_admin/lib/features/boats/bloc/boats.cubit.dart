import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../../services/logging.dart';
import '../../bookings/models/booking.model.dart';
import '../models/boats.model.dart';

part 'boats.cubit.freezed.dart';
part 'boats.cubit.mapper.dart';

class BoatsCubit extends Cubit<BoatsState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;

  BoatsCubit({required this.bookingsRepository, required this.boatsRepository})
    : super(BoatsState(status: BoatsStateStatus.initial(), selectedDate: DateTime.now()));

  Future<void> fetchBookingAndBoats() async {
    emit(state.copyWith(status: BoatsStateStatus.loading()));
    try {
      List<Boat> allBoats = await boatsRepository.fetchBoatsByDate(state.selectedDate.formatDDMMYYYY);

      List<Booking> bookings = await bookingsRepository.fetchBookings(state.selectedDate.formatDDMMYYYY);
      emit(
        state.copyWith(
          status: BoatsStateStatus.success(bookings: bookings, boats: allBoats),
        ),
      );
    } catch (e, stack) {
      Log.e('Error loading bookings for date pressed', error: e, stackTrace: stack);
      emit(state.copyWith(status: BoatsStateStatus.error(e.toString())));
    }
  }

  Future<void> updateDateTime({required DateTime selectedDate, bool refreshBookings = false}) async {
    emit(state.copyWith(selectedDate: selectedDate));
    if (refreshBookings) fetchBookingAndBoats();
  }
}

@immutable
@MappableClass()
class BoatsState with BoatsStateMappable {
  final BoatsStateStatus status;
  final DateTime selectedDate;

  BoatsState({required this.status, required this.selectedDate});
}

@freezed
abstract class BoatsStateStatus with _$BoatsStateStatus {
  const factory BoatsStateStatus.initial() = BoatsInitial;
  const factory BoatsStateStatus.loading() = BoatsLoading;
  const factory BoatsStateStatus.success({required List<Booking> bookings, required List<Boat> boats}) = BoatsSuccess;
  const factory BoatsStateStatus.error(String message) = BoatsError;
}
