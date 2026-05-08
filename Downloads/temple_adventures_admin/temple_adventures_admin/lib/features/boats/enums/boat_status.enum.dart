import 'package:dart_mappable/dart_mappable.dart';

part 'boat_status.enum.mapper.dart';

@MappableEnum(defaultValue: BoatStatus.unknown)
enum BoatStatus { unknown, ready, waitingForCaptains, leftHarbour, reachedDiveSite, diving, divesDone, docked }

extension BoatStatusX on BoatStatus {
  String get prettyName => switch (this) {
    BoatStatus.unknown => 'Unknown',
    BoatStatus.ready => 'Boat Ready',
    BoatStatus.waitingForCaptains => 'Waiting for captains',
    BoatStatus.leftHarbour => 'Left Harbour',
    BoatStatus.reachedDiveSite => 'Reached Dive Site',
    BoatStatus.diving => 'Diving',
    BoatStatus.divesDone => 'Dives done',
    BoatStatus.docked => 'Docked at Harbour',
  };
}
