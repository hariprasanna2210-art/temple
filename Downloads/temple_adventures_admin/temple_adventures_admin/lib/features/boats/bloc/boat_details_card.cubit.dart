import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';

import '../../../services/logging.dart';
import '../../bookings/models/booking.model.dart';
import '../models/boat_info.model.dart';
import '../repository/boats.repository.dart';

part 'boat_details_card.cubit.freezed.dart';
part 'boat_details_card.cubit.mapper.dart';

class BoatDetailsCardCubit extends Cubit<BoatDetailsCardState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;

  BoatDetailsCardCubit({required this.bookingsRepository, required this.boatsRepository})
    : super(BoatDetailsCardState(status: BoatDetailsCardStateStatus.initial()));

  Future<void> updateBooking(Booking booking) async {
    try {
      emit(state.copyWith(status: BoatDetailsCardStateStatus.loading()));

      if (booking.id == null) return;

      await bookingsRepository.updateBooking(booking);

      emit(state.copyWith(status: BoatDetailsCardStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error on onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: BoatDetailsCardStateStatus.error(e.toString())));
    }
  }

  Future<void> updateTankInfo(Booking booking) async {
    try {
      emit(state.copyWith(status: BoatDetailsCardStateStatus.loading()));

      if (booking.id == null || booking.bookingStatusId == null) return;

      await boatsRepository.updateTankInfo(
        tankInfo: booking.tankInfo ?? [],
        bookingStatusId: booking.bookingStatusId!,
      );

      emit(state.copyWith(status: BoatDetailsCardStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error on onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: BoatDetailsCardStateStatus.error(e.toString())));
    }
  }

  Booking? updateDiveBuddies(List<TankInfo>? selectedDiveBuddies, Booking updatedBooking) {
    // bottom sheet closed without selecting an dive buddies
    if (selectedDiveBuddies == null) return null;

    final List<TankInfo> buddies = [];
    for (final info in selectedDiveBuddies) {
      buddies.add(info.copyWith(role: Role.buddy));
    }

    // Dive Buddies are removed
    if (buddies.isEmpty) {
      List<TankInfo> tanks = updatedBooking.tankInfo ?? [];
      tanks.removeWhere((info) => info.role == Role.buddy);
      updatedBooking = updatedBooking.copyWith(tankInfo: tanks);
      updateTankInfo(updatedBooking);
      return updatedBooking;
    }

    // Dive Buddies are selected, replace the existing buddies
    List<TankInfo> tanks = updatedBooking.tankInfo ?? [];
    tanks.removeWhere((info) => info.role == Role.buddy);
    tanks.addAll(buddies);
    updatedBooking = updatedBooking.copyWith(tankInfo: tanks);
    updateTankInfo(updatedBooking);
    return updatedBooking;
  }

  Booking? updateInstructor(TankInfo? selectedInstructor, Booking updatedBooking) {
    // Case 1: Instructor unselected → remove any existing instructor
    if (selectedInstructor == null) {
      List<TankInfo> tanks = updatedBooking.tankInfo ?? [];
      tanks.removeWhere((info) => info.role == Role.instructor);
      updatedBooking = updatedBooking.copyWith(tankInfo: tanks);
      updateTankInfo(updatedBooking);
      return updatedBooking;
    }

    // Case 2: Instructor selected → replace existing instructor
    final instructor = selectedInstructor.copyWith(role: Role.instructor);
    List<TankInfo> tanks = updatedBooking.tankInfo ?? [];
    tanks.removeWhere((info) => info.role == Role.instructor);
    tanks.add(instructor);
    updatedBooking = updatedBooking.copyWith(tankInfo: tanks);
    updateTankInfo(updatedBooking);
    return updatedBooking;
  }

  Future<void> updateBoatStatus({
    required int boatStatusId,
    int? air,
    int? nitrox,
    int? boatId,
  }) async {
    try {
      emit(state.copyWith(status: BoatDetailsCardStateStatus.loading()));

      await boatsRepository.updateBoatStatus(
        air: air,
        nitrox: nitrox,
        bookingStatusId: boatStatusId,
        boatId: boatId,
      );

      emit(state.copyWith(status: BoatDetailsCardStateStatus.success()));
    } catch (e, stack) {
      Log.e('Error on updateBoatStatus: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: BoatDetailsCardStateStatus.error(e.toString())));
    }
  }
}

@immutable
@MappableClass()
class BoatDetailsCardState with BoatDetailsCardStateMappable {
  final BoatDetailsCardStateStatus status;

  const BoatDetailsCardState({required this.status});
}

@freezed
abstract class BoatDetailsCardStateStatus with _$BoatDetailsCardStateStatus {
  const factory BoatDetailsCardStateStatus.initial() = BoatDetailsCardInitial;
  const factory BoatDetailsCardStateStatus.loading() = BoatDetailsCardLoading;
  const factory BoatDetailsCardStateStatus.success() = BoatDetailsCardSuccess;
  const factory BoatDetailsCardStateStatus.error(String message) = BoatDetailsCardError;
}
