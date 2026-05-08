import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../user/enums/gender.enum.dart';

part 'customer.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class Customer with CustomerMappable {
  final int? id;
  final String? email;
  final String firstName;
  final String? lastName;
  final Gender gender;
  final String? phoneNumber;
  final String? countryCode;
  final String? isoCode;
  final String? idProofFront;
  final String? idProofBack;
  final bool? needDoctor;
  final String? paperWorkPdfPath;

  const Customer({
    this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.gender,
    required this.phoneNumber,
    required this.countryCode,
    required this.isoCode,
    this.idProofFront,
    this.idProofBack,
    this.needDoctor,
    this.paperWorkPdfPath,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();
  String get completePhoneNumber => '$countryCode$phoneNumber'.trim();

  Map<String, dynamic> toRow({bool removeId = true}) {
    final customerMap =
        toMap()
          ..remove('need_doctor')
          ..remove('paper_work_pdf_path');
    if (removeId) customerMap.remove('id');

    return customerMap;
  }
}
