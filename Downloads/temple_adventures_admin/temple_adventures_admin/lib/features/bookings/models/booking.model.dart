import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/bookings/enums/discount_type.enum.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/models/payment.model.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';
import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../activities/models/activity.model.dart';
import '../../boats/helpers/board_plan.helper.dart';
import '../../boats/models/boat_info.model.dart';
import '../../boats/models/boats.model.dart';
import '../../boats/presentation/widgets/booking_status.dart';
import '../../user/models/user.model.dart';

part 'booking.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class Booking with BookingMappable {
  final int? id;
  final Customer primaryCustomer;
  final Activity activity;
  final int noOfPersons;
  final List<Customer>? pax;
  final User createdBy;
  final List<String> bookingDate;
  @MappableField(hook: DateTimeToLocalHook())
  final List<DateTime>? poolDate;
  @MappableField(hook: DateTimeToLocalHook())
  final List<DateTime>? diveDate;
  @MappableField(hook: DateTimeToLocalHook())
  final List<DateTime>? theoryDate;
  final DiscountType? discountType;
  final double? discount;
  final double? price;
  final double? taxPercent;
  final List<Payment>? payments;
  final int? status;
  final String? equipmentNotes;
  final List<TankInfo>? tankInfo;
  final int? bookingStatusId;
  final int? air;
  final int? nitrox;
  final String? remarks;
  final bool? cancelBooking;
  final String? cancellationReason;
  final bool isQuickBooking;
  final Boat? boat;

  const Booking({
    this.id,
    required this.primaryCustomer,
    required this.noOfPersons,
    this.pax,
    this.tankInfo,
    required this.createdBy,
    required this.activity,
    this.bookingStatusId,
    this.poolDate,
    this.diveDate,
    this.theoryDate,
    this.air,
    this.nitrox,
    required this.bookingDate,

    this.discount,
    this.price,
    this.taxPercent,
    this.discountType,
    this.payments,
    this.status,
    this.equipmentNotes,
    this.boat,
    this.remarks,
    this.cancelBooking,
    this.cancellationReason,
    this.isQuickBooking = false,
  });

  Map<String, dynamic> toRow({bool includeId = false}) {
    final bookingMap =
        toMap()
          ..remove('activity')
          ..remove('primary_customer')
          ..remove('pax')
          ..remove('created_by')
          ..remove('payments')
          ..remove('booking_status_id')
          ..remove('tank_info')
          ..remove('nitrox')
          ..remove('air')
          ..remove('boat');
    if (includeId == false) bookingMap.remove('id');

    bookingMap['activity_id'] = activity.id;
    bookingMap['primary_customer_id'] = primaryCustomer.id;
    bookingMap['created_by_id'] = createdBy.id;

    return bookingMap;
  }

  TankInfo? get instructor {
    for (var info in tankInfo ?? []) {
      if (info.role == Role.instructor) {
        return info;
      }
    }
    return null;
  }

  List<TankInfo>? get buddies {
    return tankInfo?.where((info) => info.role == Role.buddy).toList();
  }

  List<DateTime>? get allDates {
    return [
      ...?poolDate,
      ...?diveDate,
      ...?theoryDate,
    ];
  }

  bool get isDSD => activity.id == 1; //TODO: remove hard coding

  String? get prettyStatus {
    List<String> statuses = isDSD ? BookingStatus.dsdStatuses : BookingStatus.courseStatuses;
    try {
      return statuses[status ?? 0];
    } catch (e) {
      return statuses[0];
    }
  }

  Future<void> updateInBoardPlan() async {
    await BoardPlanHelper.updateBoardPlanForDates(allDates);
  }
}

