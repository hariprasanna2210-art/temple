import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../services/logging.dart';
import '../model/dive_site.model.dart';
import '../../../services/loaction_service.dart';
import '../repository/dive_site.repository.dart';

part 'dive_sites.cubit.freezed.dart';

part 'dive_sites.cubit.mapper.dart';

class DiveSiteCubit extends Cubit<DiveSiteState> {
  final DiveSiteRepository repository;
  final LocationService locationService;

  DiveSiteCubit({
    required this.repository,
    required this.locationService,
  }) : super(
         const DiveSiteState(
           status: DiveSiteStatus.initial(),
           diveSites: [],
           recentLocations: [],
           showOverlay: false,
           showLoading: false,
           currentZoom: 15,
           speed: 0,
         ),
       );

  GoogleMapController? mapController;

  /// Fetch current user location
  Future<void> fetchCurrentLocation(BuildContext context, {bool hasRetried = false}) async {
    try {
      emit(state.copyWith(status: const DiveSiteStatus.loading()));

      bool isAllowed = await locationService.checkAndRequestLocationPermission(context);
      if (!isAllowed) {
        if (!context.mounted) return;
        if (!hasRetried) await fetchCurrentLocation(context, hasRetried: true);
        emit(state.copyWith(status: const DiveSiteStatus.error('Location permission denied')));
        return;
      }

      final location = await locationService.location.getLocation();
      final LatLng current = LatLng(location.latitude!, location.longitude!);

      emit(state.copyWith(currentUserLocation: current, status: const DiveSiteStatus.loaded()));

      locationService.location.onLocationChanged.listen((newLoc) {
        final newPos = LatLng(newLoc.latitude!, newLoc.longitude!);
        double speedInKmph = (newLoc.speed ?? 0) * 3.6;

        final recent = List<LatLng>.from(state.recentLocations);
        if (recent.isEmpty || recent.last != newPos) {
          recent.add(newPos);
        }
        if (recent.length > state.maxRecentLocations) {
          recent.removeAt(0);
        }

        emit(state.copyWith(currentUserLocation: newPos, recentLocations: recent, speed: speedInKmph));
      });
    } catch (e, stack) {
      Log.e('Error fetching current location', error: e, stackTrace: stack);
      if (!context.mounted) return;
      if (!hasRetried) await fetchCurrentLocation(context, hasRetried: true);
      emit(state.copyWith(status: DiveSiteStatus.error(e.toString())));
    }
  }

  /// Fetch all dive sites from repository
  Future<void> fetchDiveSites() async {
    try {
      emit(state.copyWith(status: const DiveSiteStatus.loading()));
      final diveSites = await repository.fetchAllDiveSites();
      emit(state.copyWith(diveSites: diveSites, status: const DiveSiteStatus.loaded()));
    } catch (e, stack) {
      Log.e('Error fetching dive sites', error: e, stackTrace: stack);
      emit(state.copyWith(status: DiveSiteStatus.error('Failed to fetch dive sites: $e')));
    }
  }

  void setSelectedLocation(DiveSite? site) {
    emit(state.copyWith(selectedLocation: site));
  }

  double calculateDistanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000;
  }

  void addOrEditDiveSite(DiveSite updatedDiveSite) {
    List<DiveSite> diveSites = List.of(state.diveSites);
    final index = diveSites.indexWhere((diveSite) => diveSite.id == updatedDiveSite.id);

    if (index != -1) {
      diveSites[index] = updatedDiveSite;
    } else {
      diveSites.add(updatedDiveSite);
    }
    emit(
      state.copyWith(
        diveSites: diveSites,
        selectedLocation: updatedDiveSite,
        status: DiveSiteStatus.success(
          'Dive '
          'Site updated '
          'successfully',
        ),
      ),
    );
  }

  void deleteDiveSite(int diveSiteId) {
    final updatedDiveSite = state.diveSites.where((site) => site.id != diveSiteId).toList();
    emit(state.copyWith(diveSites: updatedDiveSite, selectedLocation: null));
  }

  /// Handle map creation
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (state.currentUserLocation != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: state.currentUserLocation!, zoom: 15),
        ),
      );
    }
  }

  /// Handle camera movement
  void onCameraMove(CameraPosition position) {
    if (state.showOverlay) {
      emit(
        state.copyWith(
          currentCenterPosition: position.target,
          currentZoom: position.zoom,
        ),
      );
    }
  }

  /// Show center overlay pointer
  void showPlusPointer() {
    emit(state.copyWith(selectedLocation: null, showOverlay: true));
  }

  /// Hide overlay pointer
  void hideOverlay() {
    emit(state.copyWith(showOverlay: false));
  }

  /// Calculate distance to selected site
  double get distanceToSelectedSite {
    if (state.currentUserLocation == null || state.selectedLocation == null) return 0.0;
    return calculateDistanceInKm(
      state.currentUserLocation!.latitude,
      state.currentUserLocation!.longitude,
      state.selectedLocation!.latitude,
      state.selectedLocation!.longitude,
    );
  }
}

@immutable
@MappableClass()
class DiveSiteState with DiveSiteStateMappable {
  final DiveSiteStatus status;
  final LatLng? currentUserLocation;
  final DiveSite? selectedLocation;
  final LatLng? currentCenterPosition;
  final List<LatLng> recentLocations;
  final List<DiveSite> diveSites;
  final bool showOverlay;
  final bool showLoading;
  final double currentZoom;
  final double speed;
  final int maxRecentLocations;

  const DiveSiteState({
    required this.status,
    this.currentUserLocation,
    this.selectedLocation,
    this.currentCenterPosition,
    required this.recentLocations,
    required this.diveSites,
    required this.showOverlay,
    required this.showLoading,
    required this.currentZoom,
    required this.speed,
    this.maxRecentLocations = 5,
  });
}

@freezed
class DiveSiteStatus with _$DiveSiteStatus {
  const factory DiveSiteStatus.initial() = DiveSiteInitial;

  const factory DiveSiteStatus.loading() = DiveSiteLoading;

  const factory DiveSiteStatus.loaded() = DiveSiteLoaded;

  const factory DiveSiteStatus.success(String message) = DiveSiteSuccess;

  const factory DiveSiteStatus.error(String message) = DiveSiteError;
}
