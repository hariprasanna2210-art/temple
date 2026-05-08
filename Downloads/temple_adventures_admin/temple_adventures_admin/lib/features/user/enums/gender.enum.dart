import 'package:dart_mappable/dart_mappable.dart';

part 'gender.enum.mapper.dart';

@MappableEnum()
enum Gender { male, female }

extension GenderX on Gender {
  String get label => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
  };
}
