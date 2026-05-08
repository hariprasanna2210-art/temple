import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import '../../../../services/logging.dart';

part 'all_customers_dive_logs.cubit.freezed.dart';
part 'all_customers_dive_logs.cubit.mapper.dart';

class AllCustomersDiveLogsCubit extends Cubit<AllCustomersDiveLogsState> {
  final CustomerDiveLogsRepository repository;

  AllCustomersDiveLogsCubit({required this.repository})
    : super(const AllCustomersDiveLogsState(status: AllCustomersDiveLogsStatus.initial(), allDivLogs: []));

  /// Fetches dive logs for all customers in the list
  Future<void> fetchAllCustomersDiveLogs({
    required List<Customer> customers,
  }) async {
    try {
      emit(state.copyWith(status: AllCustomersDiveLogsStatus.loading()));

      // Fetch dive logs for all customers in parallel
      final futures =
          customers.map((customer) {
            if (customer.id == null) return Future.value(<CustomerDiveLog>[]);
            return repository.fetchCustomerDiveLogsById(customer.id!);
          }).toList();

      final results = await Future.wait(futures);

      // Flatten the list of lists into a single list
      final diveLogs = results.expand((logs) => logs).toList();

      emit(
        state.copyWith(status: AllCustomersDiveLogsStatus.success(), allDivLogs: diveLogs),
      );
    } catch (e, stack) {
      Log.e('Error while fetching all customers dive logs: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AllCustomersDiveLogsStatus.error(e.toString())));
    }
  }

  /// Replaces existing dive log if id matches else append to the list
  void replaceDiveLog(CustomerDiveLog updatedDiveLog) {
    List<CustomerDiveLog> diveLogs = List.of(state.allDivLogs);
    final index = diveLogs.indexWhere((log) => log.id == updatedDiveLog.id);

    if (index != -1) {
      diveLogs[index] = updatedDiveLog;
    } else {
      diveLogs.add(updatedDiveLog);
    }

    emit(state.copyWith(allDivLogs: diveLogs));
  }

  /// Remove a dive log from the list
  void removeDiveLog(int diveLogId) {
    final diveLogs = state.allDivLogs.where((log) => log.id != diveLogId).toList();
    emit(state.copyWith(allDivLogs: diveLogs));
  }
}

@immutable
@MappableClass()
class AllCustomersDiveLogsState with AllCustomersDiveLogsStateMappable {
  final AllCustomersDiveLogsStatus status;
  final List<CustomerDiveLog> allDivLogs;

  const AllCustomersDiveLogsState({required this.status, required this.allDivLogs});
}

@freezed
class AllCustomersDiveLogsStatus with _$AllCustomersDiveLogsStatus {
  const factory AllCustomersDiveLogsStatus.initial() = AllCustomersDiveLogsInitial;
  const factory AllCustomersDiveLogsStatus.success() = AllCustomersDiveLogsSuccess;
  const factory AllCustomersDiveLogsStatus.loading() = AllCustomersDiveLogsLoading;
  const factory AllCustomersDiveLogsStatus.error(String message) = AllCustomersDiveLogsError;
}
