import 'package:dart_mappable/dart_mappable.dart';

part 'user_type.enum.mapper.dart';

@MappableEnum()
enum UserType { showAllUsers, showCaptains, showFreelancersDivers, showDiveTeam, showInterns }

extension UserTypeX on UserType {
  String get paymentType => switch (this) {
    UserType.showAllUsers => 'showAllUsers',
    UserType.showCaptains => 'showCaptains',
    UserType.showFreelancersDivers => 'showFreelancersDivers',
    UserType.showDiveTeam => 'showDiveTeam',
    UserType.showInterns => 'showInterns',
  };
}
