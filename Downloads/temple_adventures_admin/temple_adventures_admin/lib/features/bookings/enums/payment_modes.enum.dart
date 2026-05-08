import 'package:dart_mappable/dart_mappable.dart';

part 'payment_modes.enum.mapper.dart';

@MappableEnum()
enum PaymentMode { cash, razorPay, bankTransfer, card, rose, qr }

extension PaymentModeX on PaymentMode {
  String get paymentType => switch (this) {
    PaymentMode.cash => 'Cash',
    PaymentMode.razorPay => 'Razor Pay',
    PaymentMode.bankTransfer => 'Bank Transfer',
    PaymentMode.card => 'Card',
    PaymentMode.rose => 'Rose',
    PaymentMode.qr => 'QR',
  };
}
