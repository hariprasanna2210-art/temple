import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../user/models/user.model.dart';

part 'customer_dive_log.model.mapper.dart';

@immutable
@MappableClass()
class CustomerDiveLog with CustomerDiveLogMappable {
  final int? id;
  final Customer customer;
  final User instructor;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime diveDate;
  final String diveSite;
  final String tankType;
  final int tankNo;
  final int bottomTime;
  final num maxDepth;
  final num pressure;
  final String? rentalEquipment;

  const CustomerDiveLog({
    this.id,
    required this.customer,
    required this.instructor,
    required this.diveDate,
    required this.diveSite,
    required this.tankType,
    required this.tankNo,
    required this.bottomTime,
    required this.maxDepth,
    required this.pressure,
    required this.rentalEquipment,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final customerDiveLogMap =
        toMap()
          ..remove('instructor')
          ..remove('customer');
    if (removeId) customerDiveLogMap.remove('id');

    customerDiveLogMap['instructor_id'] = instructor.id;
    customerDiveLogMap['customer_id'] = customer.id;

    return customerDiveLogMap;
  }
}
