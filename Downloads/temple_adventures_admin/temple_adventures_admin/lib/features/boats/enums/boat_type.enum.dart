import 'package:dart_mappable/dart_mappable.dart';

part 'boat_type.enum.mapper.dart';

@MappableEnum()
enum BoatType { boat, other }

extension UserTypeX on BoatType {
  String get paymentType => switch (this) {
    BoatType.boat => 'boat',
    BoatType.other => 'other',
  };
}
