import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'customer_feedback.model.mapper.dart';

@immutable
@MappableClass()
class CustomerFeedback with CustomerFeedbackMappable {
  final int? id;
  final int customerId;
  final int? bookingId;
  final bool? knowsSwimming;
  final bool? interestedOwc;
  final int? instructorFeedback;
  final int? equipmentFeedback;
  final int? experienceFeedback;
  final String? feedback;

  const CustomerFeedback({
    this.id,
    required this.customerId,
    required this.bookingId,
    required this.knowsSwimming,
    required this.interestedOwc,
    required this.instructorFeedback,
    required this.equipmentFeedback,
    required this.experienceFeedback,
    required this.feedback,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final customerFeedbackMap = toMap();
    if (removeId) customerFeedbackMap.remove('id');
    return customerFeedbackMap;
  }
}
