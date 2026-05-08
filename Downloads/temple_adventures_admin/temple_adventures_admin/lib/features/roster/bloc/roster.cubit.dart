import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/roster/models/customer_feedback.model.dart';
import 'package:temple_adventures_admin/features/roster/models/dsd_customer.model.dart';
import 'package:temple_adventures_admin/features/roster/repository/roster.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../../services/logging.dart';
import '../../boats/models/boats.model.dart';

part 'roster.cubit.freezed.dart';
part 'roster.cubit.mapper.dart';

class RosterCubit extends Cubit<RosterState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;
  final RosterRepository rosterRepository;

  RosterCubit({
    required this.bookingsRepository,
    required this.boatsRepository,
    required this.rosterRepository,
  }) : super(RosterState(status: RosterStateStatus.initial(), selectedDate: DateTime.now()));

  Future<void> selectDate(DateTime date, [bool preserveBoatSelection = false]) async {
    emit(state.copyWith(status: RosterStateStatus.loading()));
    final String formattedDate = date.formatDDMMYYYY;
    List<DSDCustomer> customers = await rosterRepository.getAllDSDCustomersWithRosterAndFeedback(formattedDate);
    List<Boat> boats = await boatsRepository.fetchBoatsByDate(formattedDate);

    // Clear previous selections when date changes
    emit(
      state.copyWith(
        selectedDate: date,
        boats: boats,
        selectedBoat: preserveBoatSelection ? state.selectedBoat : boats.firstOrNull,
        // Reset selected boat
        customers: customers,
        status: RosterStateStatus.loaded(),
      ),
    );
  }

  // Step 2: when user picks a boat
  Future<void> selectBoat(Boat? boat) async {
    if (boat?.id == null) return;
    emit(state.copyWith(selectedBoat: boat));
  }

  // Refresh data while preserving current boat selection
  Future<void> refreshData() async {
    if (state.selectedDate == null) return;
    await selectDate(state.selectedDate!, true);
  }

  // Submit customer feedback
  Future<void> submitCustomerFeedback({
    required CustomerFeedback customerFeedback,
  }) async {
    try {
      emit(state.copyWith(status: RosterStateStatus.loading()));

      await rosterRepository.addUpdateCustomerFeedback(
        customerFeedback: customerFeedback,
      );

      emit(state.copyWith(status: RosterStateStatus.loaded()));
    } catch (error) {
      Log.i(error.toString());
      emit(state.copyWith(status: RosterStateStatus.error(error.toString())));
    }
  }
}

@immutable
@MappableClass()
class RosterState with RosterStateMappable {
  final RosterStateStatus status;
  final DateTime? selectedDate;
  final Boat? selectedBoat;
  final List<Boat> boats;
  final List<DSDCustomer> customers;

  const RosterState({
    this.boats = const [],
    this.customers = const [],
    this.selectedBoat,
    required this.status,
    required this.selectedDate,
  });
}

@freezed
abstract class RosterStateStatus with _$RosterStateStatus {
  const factory RosterStateStatus.initial() = RosterInitial;
  const factory RosterStateStatus.loading() = RosterLoading;
  const factory RosterStateStatus.loaded() = RosterLoaded;
  const factory RosterStateStatus.error(String message) = RosterError;
}
