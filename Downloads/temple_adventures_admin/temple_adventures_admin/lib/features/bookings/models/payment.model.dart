import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../user/models/user.model.dart';
import '../enums/payment_modes.enum.dart';

part 'payment.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class Payment with PaymentMappable {
  final int? id;
  final User createdBy;
  final double amount;
  final PaymentMode paymentMode;
  final String? invoiceNo;
  final String? referenceNo;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime createdAt;

  const Payment({
    this.id,
    required this.createdBy,
    required this.amount,
    required this.paymentMode,
    required this.createdAt,
    this.invoiceNo,
    this.referenceNo,
  });
}
