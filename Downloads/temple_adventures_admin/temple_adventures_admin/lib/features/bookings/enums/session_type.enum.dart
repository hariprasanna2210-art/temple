import 'package:dart_mappable/dart_mappable.dart';

part 'session_type.enum.mapper.dart';

@MappableEnum()
enum SessionType { theorySession, poolSession, diveSession }

extension SessionTypeX on SessionType {
  String get sessionName => switch (this) {
    SessionType.theorySession => 'Theory Session',
    SessionType.poolSession => 'pool Session',
    SessionType.diveSession => 'Dive Session',
  };
}

