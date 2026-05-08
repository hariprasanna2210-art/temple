import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import '../../../services/logging.dart';

part 'add_customer_details.cubit.freezed.dart';
part 'add_customer_details.cubit.mapper.dart';

class AddCustomerDetailsCubit extends Cubit<AddCustomerDetailsState> {
  final BookingsRepository repository;

  AddCustomerDetailsCubit({required this.repository})
    : super(AddCustomerDetailsState(status: AddCustomerDetailsStatus.initial(), customer: null));

  ///Fetch customer if exists in db
  Future<Customer?> fetchCustomerByEmail({
    required String emailId,
    bool updateFields = true,
  }) async {
    try {
      emit(state.copyWith(status: AddCustomerDetailsStatus.loading()));
      Customer? fetchedCustomer = await repository.fetchCustomerByEmail(emailId: emailId);
      emit(
        state.copyWith(
          status: AddCustomerDetailsSuccess(updateFields: updateFields),
          customer: fetchedCustomer,
        ),
      );

      return fetchedCustomer;
    } catch (e, stack) {
      Log.e('Error handling add customer pressed', error: e, stackTrace: stack);
      emit(
        state.copyWith(
          status: AddCustomerDetailsStatus.error('Failed to fetch customer: $e'),
        ),
      );
    }
    return null;
  }

  /// Adds a customer as PAX to an existing booking
  /// If customer doesn't exist (no ID), creates the customer first
  Future<Customer?> addCustomerAsPax({
    required int bookingId,
    required Customer customer,
  }) async {
    try {
      emit(state.copyWith(status: AddCustomerDetailsStatus.loading()));

      Customer? finalCustomer = customer;

      // Step 1: If customer doesn't have ID, create customer first
      if (customer.id == null) {
        finalCustomer = await repository.addCustomer(customer);
        if (finalCustomer == null) throw Exception('Failed to create customer');
      } else {
        await repository.updateCustomer(customer);
      }

      // Step 2: Add customer as PAX to booking
      await repository.addPaxToBooking(
        bookingId: bookingId,
        customerId: finalCustomer.id!,
      );

      emit(state.copyWith(status: AddCustomerDetailsStatus.success(updateFields: false)));
      return finalCustomer; // Return the customer with ID
    } catch (e, stack) {
      emit(state.copyWith(status: AddCustomerDetailsStatus.error('Failed to add customer as PAX: $e')));
      Log.e('Error adding customer as PAX: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

@immutable
@MappableClass()
class AddCustomerDetailsState with AddCustomerDetailsStateMappable {
  final AddCustomerDetailsStatus status;
  final Customer? customer;

  const AddCustomerDetailsState({required this.customer, required this.status});
}

@freezed
abstract class AddCustomerDetailsStatus with _$AddCustomerDetailsStatus {
  const factory AddCustomerDetailsStatus.initial() = AddCustomerDetailsInitial;
  const factory AddCustomerDetailsStatus.loading() = AddCustomerDetailsLoading;
  const factory AddCustomerDetailsStatus.success({required bool updateFields}) = AddCustomerDetailsSuccess;
  const factory AddCustomerDetailsStatus.error(String message) = AddCustomerDetailsError;
}
