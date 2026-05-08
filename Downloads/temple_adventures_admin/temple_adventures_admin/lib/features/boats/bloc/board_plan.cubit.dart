import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/general_info/models/general_info.model.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../bookings/models/booking.model.dart';
import '../models/boats.model.dart';

part 'board_plan.cubit.freezed.dart';
part 'board_plan.cubit.mapper.dart';

class BoardPlanCubit extends Cubit<BoardPlanState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;

  BoardPlanCubit({required this.bookingsRepository, required this.boatsRepository})
    : super(BoardPlanState(status: BoardPlanStateStatus.initial(), selectedDate: DateTime.now()));

  Future<void> selectDate(DateTime date) async {
    emit(state.copyWith(status: BoardPlanStateStatus.loading()));
    final String formattedDate = date.formatDDMMYYYY;

    final boats = await boatsRepository.fetchBoatsByDate(formattedDate);
    final info = await boatsRepository.fetchGeneralInfoByDate(formattedDate);

    // Clear previous selections when date changes
    emit(state.copyWith(
      selectedDate: date, 
      boats: boats, 
      generalInfo: info, 
      selectedBoat: null, // Reset selected boat
      bookings: const {}, // Clear cached bookings
      status: BoardPlanStateStatus.loaded()
    ));
  }

  // Step 2: when user picks a boat
  Future<void> selectBoat(Boat? boat) async {
    if (state.selectedDate == null) return;

    // This means user selected general info
    final int? boatId = boat?.id;
    if (boatId == null) {
      emit(state.copyWith(selectedBoat: null));
      return;
    }

    emit(state.copyWith(status: BoardPlanStateStatus.loading(), selectedBoat: boat));

    final bookings = await bookingsRepository.fetchBookings(state.selectedDate!.formatDDMMYYYY, boatId: boatId);
    final stateBookings = Map.of(state.bookings);
    stateBookings[boatId] = bookings;

    emit(state.copyWith(status: BoardPlanStateStatus.loaded(), bookings: stateBookings));
  }
}

@immutable
@MappableClass()
class BoardPlanState with BoardPlanStateMappable {
  final BoardPlanStateStatus status;
  final DateTime? selectedDate;
  final List<Boat> boats;
  final Map<int, List<Booking>> bookings;
  final Boat? selectedBoat;
  final GeneralInfo? generalInfo;

  const BoardPlanState({
    this.boats = const [],
    this.bookings = const {},
    this.selectedBoat,
    this.generalInfo,
    required this.status,
    required this.selectedDate,
  });
}

@freezed
abstract class BoardPlanStateStatus with _$BoardPlanStateStatus {
  const factory BoardPlanStateStatus.initial() = BoardPlanInitial;

  const factory BoardPlanStateStatus.loading() = BoardPlanLoading;

  const factory BoardPlanStateStatus.loaded() = BoardPlanLoaded;

  const factory BoardPlanStateStatus.error(String message) = BoardPlanError;
}
