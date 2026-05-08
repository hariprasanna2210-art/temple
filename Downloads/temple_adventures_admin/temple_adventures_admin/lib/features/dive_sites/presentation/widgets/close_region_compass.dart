import 'dart:async';
import 'dart:math' show sin, cos, tan, atan;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_transform/stream_transform.dart' show CombineLatest;
import 'package:vector_math/vector_math.dart' show radians, degrees;

class CloseRegionCompass {
  final double targetLatitude;
  final double targetLongitude;
  Stream<Direction>? _directionStream;

  CloseRegionCompass(this.targetLatitude, this.targetLongitude);

  /// Request Location permission, return GeolocationStatus object
  static Future<LocationPermission> requestPermissions() => Geolocator.requestPermission();

  /// get location status: GPS enabled and the permission status with GeolocationStatus
  static Future<LocationStatus> checkLocationStatus() async {
    final status = await Geolocator.checkPermission();
    final enabled = await Geolocator.isLocationServiceEnabled();
    return LocationStatus(enabled, status);
  }

  /// Provides a stream of Map with current compass and Site direction
  /// {"qiblah": QIBLAH, "direction": DIRECTION}
  /// Direction varies from 0-360, 0 being north.
  /// Site varies from 0-360, offset from direction(North)
  Stream<Direction> get siteStream {
    _directionStream ??= _merge<CompassEvent, Position>(
      FlutterCompass.events!,
      Geolocator.getPositionStream().transform(
        StreamTransformer<Position, Position>.fromHandlers(
          handleData: (Position position, EventSink<Position> sink) {
            sink.add(position);
            sink.close();
          },
        ),
      ),
    );

    return _directionStream!;
  }

  /// Merge the compass stream with location updates, and calculate the Site direction
  /// return a Stream<Map<String, dynamic>> containing compass and Site direction
  /// Direction varies from 0-360, 0 being north.
  /// Site varies from 0-360, offset from direction(North)
  Stream<Direction> _merge<A, B>(
    Stream<A> streamA,
    Stream<B> streamB,
  ) => streamA.combineLatest<B, Direction>(
    streamB,
    (dir, pos) {
      final position = pos as Position;
      final event = dir as CompassEvent;

      // Calculate the Site offset to North
      final offSet = getOffsetFromNorth(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        targetLatitude: targetLatitude,
        targetLongitude: targetLongitude,
      );

      // Adjust Site direction based on North direction
      final site = (event.heading ?? 0.0) + (360 - offSet);

      return Direction(site, event.heading ?? 0.0, offSet);
    },
  );

  /// Close compass stream, and set Site stream to null
  void dispose() {
    _directionStream = null;
  }

  static double getOffsetFromNorth({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    var laRad = radians(currentLatitude);
    var loRad = radians(currentLongitude);

    var deLa = radians(targetLatitude);
    var deLo = radians(targetLongitude);

    var toDegrees = degrees(atan(sin(deLo - loRad) / ((cos(laRad) * tan(deLa)) - (sin(laRad) * cos(deLo - loRad)))));
    if (laRad > deLa) {
      if ((loRad > deLo || loRad < radians(-180.0) + deLo) && toDegrees > 0.0 && toDegrees <= 90.0) {
        toDegrees += 180.0;
      } else if (loRad <= deLo && loRad >= radians(-180.0) + deLo && toDegrees > -90.0 && toDegrees < 0.0) {
        toDegrees += 180.0;
      }
    }
    if (laRad < deLa) {
      if ((loRad > deLo || loRad < radians(-180.0) + deLo) && toDegrees > 0.0 && toDegrees < 90.0) {
        toDegrees += 180.0;
      }
      if (loRad <= deLo && loRad >= radians(-180.0) + deLo && toDegrees > -90.0 && toDegrees <= 0.0) {
        toDegrees += 180.0;
      }
    }
    return toDegrees;
  }
}

/// Location Status class, contains the GPS status(Enabled or not) and GeolocationStatus
class LocationStatus {
  final bool enabled;
  final LocationPermission status;

  const LocationStatus(
    this.enabled,
    this.status,
  );
}

/// Containing Site, Direction and offset
class Direction {
  final double site;
  final double direction;
  final double offset;

  const Direction(
    this.site,
    this.direction,
    this.offset,
  );
}
