extension PriceExtensions on double {
  double calculateDiscount(double discountValue, String discountType) {
    double discount = discountValue;
    if (discountType == '%') {
      discount = this * (discountValue / 100);
    }
    return discount.clamp(0, this).toDouble();
  }

  double addTax(double taxPercent) {
    if (taxPercent == 18) {
      return (this + (this * taxPercent / 100)).toDouble();
    } else {
      return this;
    }
  }

  double applyDiscountAfterTax({
    required double taxPercent,
    required double discountValue,
    required String discountType,
  }) {
    // Step 1 → Apply tax on totalPrice
    final taxedTotal = addTax(taxPercent);

    // Step 2 → Calculate discount (based on original totalPrice)
    final discount = calculateDiscount(discountValue, discountType);

    // Step 3 → Subtract discount
    return (taxedTotal - discount).clamp(0, taxedTotal).toDouble();
  }
}
