import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/roster/models/customer_feedback.model.dart';
import 'package:temple_adventures_admin/features/roster/models/roster.model.dart';

import '../../user/enums/gender.enum.dart';

part 'dsd_customer.model.mapper.dart';

@immutable
@MappableClass()
class DSDCustomer with DSDCustomerMappable {
  final int? customerId;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final int? bookingId;
  final int? boatId;
  final String? boatName;
  final CustomerFeedback? customerFeedback;
  final Roster? roster;

  const DSDCustomer({
    this.customerId,
    this.firstName,
    this.lastName,
    this.gender,
    this.customerFeedback,
    this.roster,
    this.bookingId,
    this.boatId,
    this.boatName,
  });

  String get fullName => '$firstName $lastName'.trim();
}
