import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../activities/models/activity.model.dart';
import '../../user/models/user.model.dart';

part 'all_bookings_filter.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class AllBookingsFilters with AllBookingsFiltersMappable {
  final String? searchQuery;
  final List<User>? createdBy;
  final List<Activity>? activities;
  final List<DateTime>? dateRange;
  final bool? isQuickBooking;
  final int? noOfPax;
  @MappableField(hook: DateTimeToLocalHook())
  const AllBookingsFilters({
    this.searchQuery,
    this.createdBy,
    this.activities,
    this.dateRange,
    this.isQuickBooking,
    this.noOfPax,
  });
}
