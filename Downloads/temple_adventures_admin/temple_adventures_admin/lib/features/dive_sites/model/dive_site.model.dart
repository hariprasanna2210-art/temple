import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';

part 'dive_site.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class DiveSite with DiveSiteMappable {
  final int? id;
  final String siteName;
  final double latitude;
  final double longitude;

  const DiveSite({
    this.id,
    required this.siteName,
    required this.latitude,
    required this.longitude,
  });
}
