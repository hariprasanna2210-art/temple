import 'package:dart_mappable/dart_mappable.dart';

part 'bcd.enum.mapper.dart';

@MappableEnum()
enum Bcd { kids, xxs, xs, s, m, l, xl, xxl }

extension BcdX on Bcd {
  String get label => switch (this) {
    Bcd.kids => 'Kids',
    Bcd.xxs => 'XXS',
    Bcd.xs => 'XS',
    Bcd.s => 'S',
    Bcd.m => 'M',
    Bcd.l => 'L',
    Bcd.xl => 'XL',
    Bcd.xxl => 'XXL',
  };
}
