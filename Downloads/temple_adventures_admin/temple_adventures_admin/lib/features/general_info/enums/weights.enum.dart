import 'package:dart_mappable/dart_mappable.dart';

part 'weights.enum.mapper.dart';

@MappableEnum()
enum Weights { w3, w4, w5, w6, w7 }

extension WeightsX on Weights {
  String get label => switch (this) {
    Weights.w3 => '3 kg',
    Weights.w4 => '4 kg',
    Weights.w5 => '5 kg',
    Weights.w6 => '6 kg',
    Weights.w7 => '7 kg',
  };
}
