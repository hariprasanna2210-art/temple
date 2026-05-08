import 'package:temple_adventures_admin/features/bookings/enums/discount_type.enum.dart';

class PriceCalculator {
  static double calculateDiscount({
    required double totalPrice,
    required double discountValue,
    required DiscountType discountType, // '%' or 'flat'
  }) {
    double discount = discountValue;
    if (discountType == DiscountType.percentage) {
      discount = totalPrice * (discountValue / 100);
    }
    return discount.clamp(0, totalPrice);
  }

  static double calculateTotalWithTaxAndDiscount({
    required double totalPrice,
    required double taxPercent,
    required double discountValue,
    required DiscountType discountType,
  }) {
    double total = totalPrice;

    if (taxPercent == 18) {
      total += totalPrice * (taxPercent / 100);
    }

    double discount = calculateDiscount(
      totalPrice: totalPrice,
      discountValue: discountValue,
      discountType: discountType,
    );

    total -= discount;

    return total;
  }
}
