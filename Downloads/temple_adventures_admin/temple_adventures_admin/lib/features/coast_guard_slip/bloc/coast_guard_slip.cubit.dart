import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/boats/enums/boat_type.enum.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/services/share.service.dart';

import '../../../services/logging.dart';
import '../../../services/pdf_generators/coast_guard_slip_pdf_generator.dart';
import '../../../services/pdf_generators/id_proofs_pdf_generator.dart';
import '../../boats/models/boats.model.dart';
import '../../boats/repository/boats.repository.dart';
import '../../bookings/models/booking.model.dart';

part 'coast_guard_slip.cubit.freezed.dart';
part 'coast_guard_slip.cubit.mapper.dart';

class CoastGuardSlipCubit extends Cubit<CoastGuardSlipState> {
  final BookingsRepository bookingsRepository;
  final BoatsRepository boatsRepository;

  CoastGuardSlipCubit({
    required this.bookingsRepository,
    required this.boatsRepository,
  }) : super(CoastGuardSlipState(status: CoastGuardSlipStatus.initial(), selectedDate: DateTime.now()));

  Future<void> selectDate(DateTime date) async {
    emit(state.copyWith(status: CoastGuardSlipStatus.loading()));

    try {
      final String formattedDate = date.formatDDMMYYYY;

      // Fetch all boats for the selected date
      final allBoats = await boatsRepository.fetchBoatsByDate(formattedDate);

      // Filter boats by type (only show boats where type = "boat")
      final boats = allBoats.where((boat) => boat.type == BoatType.boat).toList();

      // Fetch all bookings for the selected date
      final allBookings = await bookingsRepository.fetchBookings(formattedDate);

      // Group bookings by boat (only for visible boats)
      final Map<int, List<Booking>> bookingsByBoat = {};
      for (final booking in allBookings) {
        if (booking.boat?.id != null) {
          final boatId = booking.boat!.id!;
          // Only include bookings for visible boats
          if (boats.any((boat) => boat.id == boatId)) {
            if (!bookingsByBoat.containsKey(boatId)) {
              bookingsByBoat[boatId] = [];
            }
            bookingsByBoat[boatId]!.add(booking);
          }
        }
      }

      emit(
        state.copyWith(
          selectedDate: date,
          boats: boats,
          bookingsByBoat: bookingsByBoat,
          status: CoastGuardSlipStatus.loaded(),
        ),
      );
    } catch (e, stack) {
      Log.e('Failed to load coast guard slip data', error: e, stackTrace: stack);
      emit(
        state.copyWith(
          status: CoastGuardSlipStatus.error('Failed to load data: $e'),
        ),
      );
    }
  }

  Future<void> generateAndSharePdf() async {
    if (state.boats.isEmpty || state.bookingsByBoat.isEmpty) {
      emit(
        state.copyWith(
          status: CoastGuardSlipStatus.error('No data available to generate PDF'),
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(status: CoastGuardSlipStatus.generating()));

      // Generate PDF using existing PDF generator service
      final pdfFile = await CoastGuardSlipPdfGenerator.generate(
        boats: state.boats,
        bookingsByBoat: state.bookingsByBoat,
        selectedDate: state.selectedDate!,
      );

      // Share PDF
      await ShareService.shareFile(
        file: pdfFile,
        text: 'Coast Guard Slip - ${state.selectedDate!.formatDDMMYYYY}',
      );

      emit(state.copyWith(status: CoastGuardSlipStatus.success()));
    } catch (e, stack) {
      Log.e('Failed to generate coast guard slip PDF', error: e, stackTrace: stack);
      emit(
        state.copyWith(
          status: CoastGuardSlipStatus.error('Failed to generate PDF: $e'),
        ),
      );
    }
  }

  Future<void> generateAndShareIdProofsPdf() async {
    if (state.boats.isEmpty || state.bookingsByBoat.isEmpty) {
      emit(
        state.copyWith(
          status: CoastGuardSlipStatus.error('No data available to generate PDF'),
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(status: CoastGuardSlipStatus.generating()));

      // Generate ID Proofs PDF
      final pdfFile = await IdProofsPdfGenerator.generate(
        boats: state.boats,
        bookingsByBoat: state.bookingsByBoat,
        selectedDate: state.selectedDate!,
      );

      // Share PDF
      await ShareService.shareFile(
        file: pdfFile,
        text: 'ID Proofs - ${state.selectedDate!.formatDDMMYYYY}',
      );

      emit(state.copyWith(status: CoastGuardSlipStatus.success()));
    } catch (e, stack) {
      Log.e('Failed to generate ID proofs PDF', error: e, stackTrace: stack);
      String errorMessage = 'Failed to generate ID Proofs PDF';
      if (e.toString().contains('TooManyPagesException') || e.toString().contains('too large')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'Failed to generate ID Proofs PDF: ${e.toString()}';
      }
      emit(
        state.copyWith(
          status: CoastGuardSlipStatus.error(errorMessage),
        ),
      );
    }
  }
}

@immutable
@MappableClass()
class CoastGuardSlipState with CoastGuardSlipStateMappable {
  final CoastGuardSlipStatus status;
  final DateTime? selectedDate;
  final List<Boat> boats;
  final Map<int, List<Booking>> bookingsByBoat;

  const CoastGuardSlipState({
    required this.status,
    required this.selectedDate,
    this.boats = const [],
    this.bookingsByBoat = const {},
  });
}

@freezed
abstract class CoastGuardSlipStatus with _$CoastGuardSlipStatus {
  const factory CoastGuardSlipStatus.initial() = CoastGuardSlipInitial;
  const factory CoastGuardSlipStatus.loading() = CoastGuardSlipLoading;
  const factory CoastGuardSlipStatus.loaded() = CoastGuardSlipLoaded;
  const factory CoastGuardSlipStatus.generating() = CoastGuardSlipGenerating;
  const factory CoastGuardSlipStatus.success() = CoastGuardSlipSuccess;
  const factory CoastGuardSlipStatus.error(String message) = CoastGuardSlipError;
}
