import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class OTAService {
  final ShorebirdUpdater _updater;
  bool _isUpdaterAvailable = false;
  Patch? _currentPatch;

  OTAService(this._updater) {
    initialize();
  }

  Future<void> initialize() async {
    _isUpdaterAvailable = _updater.isAvailable;

    try {
      _currentPatch = await _updater.readCurrentPatch();
    } catch (e) {
      debugPrint('Error reading current patch: $e');
    }
  }

  bool get isUpdaterAvailable => _isUpdaterAvailable;

  Patch? get currentPatch => _currentPatch;

  Future<UpdateStatus> checkForUpdate({UpdateTrack track = UpdateTrack.stable}) async {
    return await _updater.checkForUpdate(track: track);
  }

  Future<void> update({
    UpdateTrack track = UpdateTrack.stable,
  }) async {
    return await _updater.update(track: track);
  }

  Future<String> getAppCombinedVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;
      return '$currentVersion+$currentBuildNumber';
    } catch (e) {
      debugPrint('Error fetching app version: $e');
      return 'unknown';
    }
  }
}
