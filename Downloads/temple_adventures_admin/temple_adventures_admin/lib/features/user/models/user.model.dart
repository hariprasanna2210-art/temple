import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../enums/access_levels.enum.dart';
import '../enums/gender.enum.dart';
import '../enums/roles.enum.dart';

part 'user.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class User with UserMappable {
  final int? id;
  final Gender gender;
  final String phoneNumber;
  final String countryCode;
  final String isoCode;
  final Roles role;
  final String firstName;
  final String? lastName;
  final String? nickName;
  final String? padiNo;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? leaveStartDate;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? leaveEndDate;
  final List<AccessLevels>? accessLevels;
  final bool isDeleted;

  const User({
    this.id,
    required this.gender,
    required this.phoneNumber,
    required this.countryCode,
    required this.isoCode,
    required this.role,
    required this.firstName,
    this.leaveStartDate,
    this.leaveEndDate,
    this.lastName,
    this.nickName,
    this.padiNo,
    this.accessLevels,
    this.isDeleted = false,
  });
  String get fullName => '$firstName ${lastName ?? ''}'.trim();
}
