import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/bloc/all_customers_dive_logs.cubit.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/utils/dive_log_helpers.dart';
import '../../../../services/logging.dart';

part 'copy_customer_dive_logs.cubit.freezed.dart';
part 'copy_customer_dive_logs.cubit.mapper.dart';

class CopyCustomerDiveLogsCubit extends Cubit<CopyCustomerDiveLogsState> {
  final CustomerDiveLogsRepository repository;

  CopyCustomerDiveLogsCubit({required this.repository})
    : super(const CopyCustomerDiveLogsState(status: CopyCustomerDiveLogsStatus.initial()));

  Future<void> copyLogs(
    BuildContext context, {
    required List<Customer> allCustomers,
    required List<CustomerDiveLog> allDiveLogs,
    required String copyFromEmail,
    required String copyToEmail,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      emit(state.copyWith(status: CopyCustomerDiveLogsStatus.loading()));

      // Validate same customer
      if (copyFromEmail == copyToEmail) {
        emit(
          state.copyWith(
            status: CopyCustomerDiveLogsStatus.error('Cannot copy logs to the same customer'),
          ),
        );
        return;
      }

      // Find customers by email
      final copyFromCustomer = allCustomers.firstWhere(
        (c) => c.email?.toLowerCase() == copyFromEmail,
        orElse: () => throw Exception('Customer with email "$copyFromEmail" not found'),
      );

      final copyToCustomer = allCustomers.firstWhere(
        (c) => c.email?.toLowerCase() == copyToEmail,
        orElse: () => throw Exception('Customer with email "$copyToEmail" not found'),
      );

      // Filter dive logs by customer and date range (inclusive)
      final logsToC = DiveLogHelpers.filterLogsByDateRange(
        logs: allDiveLogs,
        customerId: copyFromCustomer.id!,
        startDate: startDate,
        endDate: endDate,
      );

      if (logsToC.isEmpty) {
        emit(
          state.copyWith(
            status: CopyCustomerDiveLogsStatus.error(
              'No dive logs found for the selected customer in the date range',
            ),
          ),
        );
        return;
      }

      // Create new logs for the "copy to" customer
      final copiedLogs = <CustomerDiveLog>[];
      for (final log in logsToC) {
        final newLog = DiveLogHelpers.createCopiedLog(log, copyToCustomer);
        final savedLog = await repository.addUpdateCustomerDiveLog(diveLog: newLog);
        copiedLogs.add(savedLog);
      }

      // Update the parent cubit state with new logs
      if (context.mounted) {
        for (final log in copiedLogs) {
          context.read<AllCustomersDiveLogsCubit>().replaceDiveLog(log);
        }
      }

      emit(
        state.copyWith(status: CopyCustomerDiveLogsStatus.success()),
      );
    } catch (e, stack) {
      Log.e('Error copying dive logs: $e', error: e, stackTrace: stack);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          status: CopyCustomerDiveLogsStatus.error(errorMessage),
        ),
      );
    }
  }
}

@immutable
@MappableClass()
class CopyCustomerDiveLogsState with CopyCustomerDiveLogsStateMappable {
  final CopyCustomerDiveLogsStatus status;

  const CopyCustomerDiveLogsState({required this.status});
}

@freezed
class CopyCustomerDiveLogsStatus with _$CopyCustomerDiveLogsStatus {
  const factory CopyCustomerDiveLogsStatus.initial() = CopyCustomerDiveLogsInitial;
  const factory CopyCustomerDiveLogsStatus.success() = CopyCustomerDiveLogsSuccess;
  const factory CopyCustomerDiveLogsStatus.loading() = CopyCustomerDiveLogsLoading;
  const factory CopyCustomerDiveLogsStatus.error(String message) = CopyCustomerDiveLogsError;
}
