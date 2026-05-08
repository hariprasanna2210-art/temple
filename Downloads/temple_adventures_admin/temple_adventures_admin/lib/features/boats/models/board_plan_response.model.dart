import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';

import '../../bookings/models/booking.model.dart';
import '../../events/models/event.model.dart';
import '../../general_info/models/general_info.model.dart';
import 'boats.model.dart';

part 'board_plan_response.model.mapper.dart';

@immutable
@MappableClass()
class BoardPlanResponse with BoardPlanResponseMappable {
  final List<Boat> boats;
  final GeneralInfo? generalInfo;
  final List<Booking> bookings;
  final List<EventModel> events;

  const BoardPlanResponse({
    required this.boats,
    required this.generalInfo,
    required this.bookings,
    required this.events,
  });
}
