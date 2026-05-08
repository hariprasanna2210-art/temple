import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'ota_info.model.mapper.dart';

@immutable
@MappableClass()
class OTAInfo with OTAInfoMappable {
  final String androidVersionNumber;
  final String iosVersionNumber;
  final String appStoreLink;
  final String playStoreLink;
  final bool criticalUpdate;

  const OTAInfo({
    required this.androidVersionNumber,
    required this.iosVersionNumber,
    required this.appStoreLink,
    required this.playStoreLink,
    required this.criticalUpdate,
  });
}