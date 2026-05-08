import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/bloc/all_customers_dive_logs.cubit.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/repository/customer_dive_logs.repository.dart';
import '../../../../services/logging.dart';

part 'add_edit_customer_dive_log.cubit.freezed.dart';
part 'add_edit_customer_dive_log.cubit.mapper.dart';

class AddEditCustomerDiveLogCubit extends Cubit<AddEditCustomerDiveLogState> {
  final CustomerDiveLogsRepository repository;

  AddEditCustomerDiveLogCubit({required this.repository})
    : super(const AddEditCustomerDiveLogState(status: AddEditCustomerDiveLogStatus.initial()));

  Future<void> onSubmit(BuildContext context, CustomerDiveLog customerDiveLog) async {
    try {
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.loading()));
      
      final savedDiveLog = await repository.addUpdateCustomerDiveLog(diveLog: customerDiveLog);
      
      if (context.mounted) {
        context.read<AllCustomersDiveLogsCubit>().replaceDiveLog(savedDiveLog);
      }
      
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.success()));
    } catch (e, stack) {
      Log.e('Error in onSubmit: $e', error: e, stackTrace: stack);
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.error(e.toString())));
    }
  }

  Future<void> deleteDiveLog(BuildContext context, int diveLogId) async {
    try {
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.loading()));
      await repository.deleteDiveLog(diveLogId);
      
      if (context.mounted) {
        context.read<AllCustomersDiveLogsCubit>().removeDiveLog(diveLogId);
      }
      
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.success()));
    } catch (e, stack) {
      emit(state.copyWith(status: AddEditCustomerDiveLogStatus.error('Error occurred in delete: ${e.toString()}')));
      Log.e('Error deleting diveLog', error: e, stackTrace: stack);
    }
  }
}

@immutable
@MappableClass()
class AddEditCustomerDiveLogState with AddEditCustomerDiveLogStateMappable {
  final AddEditCustomerDiveLogStatus status;

  const AddEditCustomerDiveLogState({required this.status});
}

@freezed
class AddEditCustomerDiveLogStatus with _$AddEditCustomerDiveLogStatus {
  const factory AddEditCustomerDiveLogStatus.initial() = AddEditCustomerDiveLogInitial;
  const factory AddEditCustomerDiveLogStatus.success() = AddEditCustomerDiveLogSuccess;
  const factory AddEditCustomerDiveLogStatus.loading() = AddEditCustomerDiveLogLoading;
  const factory AddEditCustomerDiveLogStatus.error(String message) = AddEditCustomerDiveLogError;
}
