import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/utils/dive_log_helpers.dart';
import 'package:temple_adventures_admin/services/share.service.dart';
import '../../../services/logging.dart';
import '../../../services/pdf_generators/customer_dive_logs_pdf_generator.dart';

part 'generate_customer_dive_logs.cubit.freezed.dart';
part 'generate_customer_dive_logs.cubit.mapper.dart';

class GenerateCustomerDiveLogsCubit extends Cubit<GenerateCustomerDiveLogsState> {
  final CustomerDiveLogsRepository repository;

  GenerateCustomerDiveLogsCubit({required this.repository})
    : super(
        const GenerateCustomerDiveLogsState(
          status: GenerateCustomerDiveLogsStatus.initial(),
        ),
      );

  Future<void> generateAndSharePdf({
    required String email,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    emit(state.copyWith(status: const GenerateCustomerDiveLogsStatus.loading()));

    try {
      final allLogs = await _validateEmailAndFetchLogs(normalizedEmail);

      List<CustomerDiveLog> filteredLogs = allLogs;

      // Filter by date range if provided
      if (startDate != null && endDate != null) {
        filteredLogs = DiveLogHelpers.filterLogsByDateRange(
          logs: allLogs,
          customerId: null, // No customer filter, only date range
          startDate: startDate,
          endDate: endDate,
        );

        if (filteredLogs.isEmpty) {
          return emit(
            state.copyWith(
              status: GenerateCustomerDiveLogsStatus.error('No dive logs found for the selected date range'),
            ),
          );
        }
      }

      // Sort logs by date (newest first)
      DiveLogHelpers.sortByDate(filteredLogs, newestFirst: true);

      await _generateAndSharePdfFile(
        logs: filteredLogs,
        startDate: startDate,
        endDate: endDate,
      );

      emit(state.copyWith(status: const GenerateCustomerDiveLogsStatus.success()));
    } catch (e, stack) {
      Log.e('Error generating or sharing dive logs PDF: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: GenerateCustomerDiveLogsStatus.error(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<List<CustomerDiveLog>> _validateEmailAndFetchLogs(String email) async {
    try {
      final logs = await repository.fetchCustomerDiveLogsByEmail(email: email);
      if (logs.isEmpty) throw Exception('No dive logs found for this customer');
      return logs;
    } catch (e) {
      throw Exception('No customer found with email "$email"');
    }
  }

  Future<void> _generateAndSharePdfFile({
    required List<CustomerDiveLog> logs,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final customer = logs.first.customer;

    final pdfFile = await CustomerDiveLogsPdfGenerator.generate(
      customer: customer,
      diveLogs: logs,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      await ShareService.shareFile(
        file: pdfFile,
        subject: 'Customer Dive Logs from Temple Adventures',
        text: 'Dive Logs - ${customer.fullName}',
      );
    } catch (e, stack) {
      Log.e('Error sharing generated PDF: $e', error: e, stackTrace: stack);
      throw Exception('Failed to share PDF file');
    }
  }
}

@immutable
@MappableClass()
class GenerateCustomerDiveLogsState with GenerateCustomerDiveLogsStateMappable {
  final GenerateCustomerDiveLogsStatus status;

  const GenerateCustomerDiveLogsState({required this.status});
}

@freezed
class GenerateCustomerDiveLogsStatus with _$GenerateCustomerDiveLogsStatus {
  const factory GenerateCustomerDiveLogsStatus.initial() = GenerateCustomerDiveLogsInitial;
  const factory GenerateCustomerDiveLogsStatus.success() = GenerateCustomerDiveLogsSuccess;
  const factory GenerateCustomerDiveLogsStatus.loading() = GenerateCustomerDiveLogsLoading;
  const factory GenerateCustomerDiveLogsStatus.error(String message) = GenerateCustomerDiveLogsError;
}
