import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../user/models/user.model.dart';

part 'offer.model.mapper.dart';

@immutable
@MappableClass()
class Offer with OfferMappable {
  final int? id;
  final String name;
  final String? description;
  final String photo;
  final User createdBy;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime startDate;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime endDate;

  const Offer({
    this.id,
    required this.name,
    this.description,
    required this.photo,
    required this.createdBy,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final offerMap = toMap()..remove('created_by');
    if (removeId) offerMap.remove('id');

    offerMap['created_by_id'] = createdBy.id;

    return offerMap;
  }
}
