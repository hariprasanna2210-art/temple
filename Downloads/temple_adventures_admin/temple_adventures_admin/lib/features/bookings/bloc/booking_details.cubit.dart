import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Cubit;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';

import '../../../services/logging.dart';
import '../../../utils/supabase_error_helper.dart';

part 'booking_details.cubit.freezed.dart';
part 'booking_details.cubit.mapper.dart';

class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final BookingsRepository repository;
  final LogsRepository logRepository;

  BookingDetailsCubit({required this.repository, required this.logRepository})
    : super(BookingDetailsState(status: BookingDetailsStatus.initial()));

  Future<void> addBooking(Booking bookingModel) async {
    try {
      emit(state.copyWith(status: BookingDetailsStatus.loading()));
      final int? updatedBookingId = await repository.addBooking(bookingModel);
      if (updatedBookingId != null) {
        await logRepository.addLog(actionType: ActionType.bookingCreated, referenceId: updatedBookingId);

        // Update board plan after successful booking
        await bookingModel.updateInBoardPlan();

      }
      emit(state.copyWith(status: BookingDetailsStatus.success()));
    } catch (e, stack) {
      Log.e('Error handling add booking pressed', error: e, stackTrace: stack);
      
      // Provide user-friendly error message
      String errorMessage = SupabaseErrorHelper.getSupabaseErrorMessage(e);
      
      // Check for specific "net" schema error
      if (e.toString().contains('schema "net" does not exist') || 
          e.toString().contains('schema \\"net\\"')) {
        errorMessage = 'Database configuration error: Missing schema. Please contact support.';
        
        // Send to Sentry with context
        SentryHelper.captureException(
          e,
          stackTrace: stack,
          extra: {
            'error_type': 'database_schema_error',
            'schema_name': 'net',
            'operation': 'addBooking',
          },
          tag: 'supabase_database',
        );
      }
      
      emit(state.copyWith(status: BookingDetailsStatus.error(errorMessage)));
    }
  }
}

@immutable
@MappableClass()
class BookingDetailsState with BookingDetailsStateMappable {
  final BookingDetailsStatus status;

  const BookingDetailsState({required this.status});
}

@freezed
class BookingDetailsStatus with _$BookingDetailsStatus {
  const factory BookingDetailsStatus.initial() = BookingDetailsInitial;
  const factory BookingDetailsStatus.loading() = BookingDetailsLoading;
  const factory BookingDetailsStatus.success() = BookingDetailsSuccess;
  const factory BookingDetailsStatus.error(String message) = BookingDetailsError;
}
