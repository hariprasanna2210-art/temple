import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'activity_color.model.mapper.dart';

@immutable
@MappableClass()
class ActivityColor with ActivityColorMappable {
  final int? id;
  final String name;
  final String color;

  const ActivityColor({this.id, required this.name, required this.color});
}
