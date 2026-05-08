import 'package:dart_mappable/dart_mappable.dart';

part 'roles.enum.mapper.dart';

@MappableEnum()
enum Roles {
  officeStaff,
  adminTeam,
  diveTeam,
  accountsTeam,
  frontDeskTeam,
  marketingTeam,
  captainTeam,
  bookingsTeam,
  socialMedia,
  freelanceTeam,
  intern,
}

extension RolesX on Roles {
  String get label => switch (this) {
    Roles.officeStaff => 'Office Staff',
    Roles.adminTeam => 'Admin Team',
    Roles.diveTeam => 'Dive Team',
    Roles.accountsTeam => 'Accounts Team',
    Roles.frontDeskTeam => 'Front Desk Team',
    Roles.marketingTeam => 'Marketing Team',
    Roles.captainTeam => 'Captain Team',
    Roles.bookingsTeam => 'Bookings Team',
    Roles.socialMedia => 'Social Media',
    Roles.freelanceTeam => 'Freelance Team',
    Roles.intern => 'Intern',
  };
}
