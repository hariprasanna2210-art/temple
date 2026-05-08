// Function to calculate the bearing between two points
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateBearing(LatLng start, LatLng end) {
  double startLatRad = radians(start.latitude);
  double startLonRad = radians(start.longitude);
  double endLatRad = radians(end.latitude);
  double endLonRad = radians(end.longitude);

  double deltaLon = endLonRad - startLonRad;

  double y = sin(deltaLon) * cos(endLatRad);
  double x = cos(startLatRad) * sin(endLatRad) - sin(startLatRad) * cos(endLatRad) * cos(deltaLon);

  return (degrees(atan2(y, x)) + 360) % 360; // Normalize to 0-360
}

// Function to calculate the destination point given a start point, distance, and bearing
LatLng destinationPoint(LatLng start, double distance, double bearing) {
  double earthRadius = 6371000; // Earth's radius in meters
  double distanceRatio = distance / earthRadius;

  double startLatRad = radians(start.latitude);
  double startLonRad = radians(start.longitude);

  double destLatRad = asin(
    sin(startLatRad) * cos(distanceRatio) + cos(startLatRad) * sin(distanceRatio) * cos(radians(bearing)),
  );

  double destLonRad =
      startLonRad +
      atan2(
        sin(radians(bearing)) * sin(distanceRatio) * cos(startLatRad),
        cos(distanceRatio) - sin(startLatRad) * sin(destLatRad),
      );

  return LatLng(degrees(destLatRad), degrees(destLonRad));
}

// Convert degrees to radians
double radians(double degrees) {
  return degrees * (pi / 180);
}

// Convert radians to degrees
double degrees(double radians) {
  return radians * (180 / pi);
}

// Function to calculate the distance to the edge of the map based on the zoom level
double calculateDistanceToEdge(double mapWidth, double mapHeight, double zoomLevel) {
  // You can adjust this based on your specific map's scaling and how much distance
  // corresponds to each pixel at the current zoom level. This is a rough estimate.
  double metersPerPixel = 156543.03 * cos(radians(11.983048)) / (pow(2, zoomLevel));

  // Calculate half the diagonal distance to the edge of the map
  double diagonalDistance = sqrt(pow(mapWidth, 2) + pow(mapHeight, 2)) / 2 * metersPerPixel;

  return diagonalDistance; // Return the distance to the edge
}

LatLng getNextPointOnLine(LatLng start, LatLng end, double mapWidth, double mapHeight, double zoomLevel) {
  // Calculate the bearing from start to end
  double bearing = calculateBearing(start, end);

  // Calculate the distance to the edge of the map
  // Here we assume the map covers a certain distance at the current zoom level
  double distanceToEdge = calculateDistanceToEdge(mapWidth, mapHeight, zoomLevel) * 100;

  // Calculate the next point at the edge
  return destinationPoint(start, distanceToEdge, bearing);
}
