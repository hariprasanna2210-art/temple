import 'package:dart_mappable/dart_mappable.dart';

part 'discount_type.enum.mapper.dart';

@MappableEnum()
enum DiscountType { rupees, percentage }

extension DiscountTypeX on DiscountType {
  String get paymentType => switch (this) {
    DiscountType.rupees => 'Rupees',
    DiscountType.percentage => 'Percentage',
  };
}
