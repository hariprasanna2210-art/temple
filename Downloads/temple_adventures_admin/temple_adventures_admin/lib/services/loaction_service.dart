import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import '../widgets/custom_alert_dialog.dart';

class LocationService {
  final Location location = Location();

  Future<bool> checkAndRequestLocationPermission(BuildContext context) async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (!context.mounted) return false;
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          title: 'Location Service Disabled',
          message: 'Please enable GPS to continue using location features.',
        );
        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return false;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (!context.mounted) return false;

        await _showPermissionDialog(
          context,
          title: 'Permission Denied',
          message: 'Location permission is required to use this feature.',
        );
        return false;
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      if (!context.mounted) return false;

      final shouldOpenSettings = await _showPermissionDialog(
        context,
        title: 'Permission Required',
        message: 'Please enable location access from the app settings.',
      );
      if (shouldOpenSettings == true) {
        await AppSettings.openAppSettings();
      }
      return false;
    }

    return true;
  }

  Future<bool?> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return false;
    return await CustomAlertDialog.show(
      context,
      title: title,
      content: message,
    );
  }
}
