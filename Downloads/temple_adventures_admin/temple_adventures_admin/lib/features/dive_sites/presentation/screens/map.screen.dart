import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../utils/map_calculation.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../bloc/dive_sites.cubit.dart';
import '../widgets/close_region_navigation_helper.screen.dart';
import '../widgets/location_details.modal.dart';
import '../widgets/overlay_icon.widget.dart';
import 'all_dive_sites.screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const MapScreen());

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  bool expandLocationDetails = true;
  bool showDeadHeading = false;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<DiveSiteCubit>();
      cubit.fetchCurrentLocation(context);
      cubit.setSelectedLocation(null);
      cubit.fetchDiveSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DiveSiteCubit>();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Temple Maps',
        description: 'Friendly navigation helper',
        action: Row(
          children: [
            IconButton(
              onPressed: () async {
                final diveSite = await Navigator.push(context, AllDiveSitesView.route());
                if (diveSite == null) {
                  debugPrint('the divesite is $diveSite');
                  return;
                }
                cubit.setSelectedLocation(diveSite);
                cubit.mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        diveSite.latitude,
                        diveSite.longitude,
                      ),
                      zoom: 15,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.travel_explore),
            ),
            IconButton(
              onPressed: cubit.showPlusPointer,
              icon: const Icon(Icons.add_location_alt),
            ).paddingOnly(right: 20),
          ],
        ),
      ),
      body: BlocConsumer<DiveSiteCubit, DiveSiteState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.status is DiveSiteLoading || state.currentUserLocation == null) {
            return CircularProgressIndicator().center;
          }
          if (state.status is DiveSiteError) {
            final message = (state.status as DiveSiteError).message;
            return EmptyStateMessage(
              message: 'Failed to load equipment\n$message',
              onRetry: () {
                final cubit = context.read<DiveSiteCubit>();
                cubit.fetchCurrentLocation(context);
              },
            );
          }
          if (state.status is DiveSiteLoaded || state.status is DiveSiteSuccess) {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: cubit.onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: state.currentUserLocation!,
                    zoom: 20,
                  ),
                  onTap: (_) {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _buildMarkers(state),
                  polylines: _buildPolyLines(state),
                  onCameraMove: cubit.onCameraMove,
                  zoomControlsEnabled: false,
                ),
                if (state.currentUserLocation != null && state.selectedLocation != null)
                  Positioned(
                    bottom: 28,
                    child: AnimatedContainer(
                      height: (expandLocationDetails ? 85 : 240) + 100,
                      duration: Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Spacer(),
                              SpeedIndicator(
                                speedKmph: state.speed,
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child:
                                      CloseRegionNavigationHelperScreen(
                                        targetLatitude: state.selectedLocation!.latitude,
                                        targetLongitude: state.selectedLocation!.longitude,
                                        isWidget: true,
                                        diveSiteName: state.selectedLocation?.siteName ?? '',
                                      ).paddingAll(16).center,
                                ),
                              ),
                              Spacing.w16,
                            ],
                          ).width(Screen.width),
                          InkWell(
                            onTap: () {
                              setState(() {
                                expandLocationDetails = !expandLocationDetails;
                              });
                            },
                            child: Container(
                              height: 76,
                              width: Screen.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${state.selectedLocation?.siteName}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              text: 'You are ',
                                              style: DefaultTextStyle.of(
                                                context,
                                              ).style.copyWith(color: Colors.black87.withOpacity(0.7)),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: '${(cubit.distanceToSelectedSite).toStringAsFixed(2)} kms',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: cubit.distanceToSelectedSite < 2 ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                                TextSpan(text: ' away from current location'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Transform.rotate(
                                          angle: pi * (expandLocationDetails ? 2 : 1),
                                          child: Icon(Icons.keyboard_control_key).paddingOnly(top: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ).paddingAll(16),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Container(
                                color: Colors.white,
                                width: Screen.width,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Coordinates :',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${state.selectedLocation!.latitude}, ${state.selectedLocation!.longitude}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Spacing.h20,
                                    AppButton.flat(
                                      text: 'Compass Navigation',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          CloseRegionNavigationHelperScreen.route(
                                            targetLatitude: state.selectedLocation!.latitude,
                                            targetLongitude: state.selectedLocation!.longitude,
                                            diveSite: state.selectedLocation?.siteName ?? '',
                                          ),
                                        );
                                      },
                                      width: Screen.width,
                                    ),
                                  ],
                                ).paddingHorizontal(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.showOverlay && state.currentCenterPosition != null) ...[
                  OverlayIconWidget(),
                  Positioned(
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AppButton.flat(
                          text: 'Cancel',
                          buttonColor: Colors.black,

                          onTap: () {
                            cubit.hideOverlay();
                          },
                        ),
                        AppButton.flat(
                          text: 'Add location',
                          onTap: () async {
                            LocationDetailsModal.show(context);
                          },
                        ),
                      ],
                    ).width(Screen.width),
                  ),
                ],
                Positioned(
                  top: 12,
                  left: 12,
                  child: SpeedIndicator(
                    speedKmph: state.speed,
                  ),
                ),
                Positioned(
                  top: 12 + 38 + 12,
                  right: 12,
                  child: InkWell(
                    onTap: () => setState(() => showDeadHeading = !showDeadHeading),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: showDeadHeading ? Colors.black : Colors.white70,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            bottom: 5,
                            left: 18,
                            child: Container(
                              height: 30,
                              width: 2,
                              color: Colors.red,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 7,
                            child: Icon(
                              Icons.navigation_rounded,
                              color: !showDeadHeading ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return EmptyStateMessage(message: 'something went wrong');
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(DiveSiteState state) {
    final cubit = context.read<DiveSiteCubit>();
    return {
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: state.currentUserLocation!,
        infoWindow: const InfoWindow(title: 'Current location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      ...state.diveSites.map((site) {
        return Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          markerId: MarkerId(site.siteName),
          position: LatLng(site.latitude, site.longitude),
          infoWindow: InfoWindow(title: site.siteName),
          onTap: () => cubit.setSelectedLocation(site),
        );
      }),
    };
  }

  Set<Polyline> _buildPolyLines(DiveSiteState state) {
    return {
      if (state.currentUserLocation != null && state.selectedLocation != null)
        Polyline(
          polylineId: const PolylineId('navigation_line'),
          points: [
            state.currentUserLocation!,
            LatLng(
              state.selectedLocation!.latitude,
              state.selectedLocation!.longitude,
            ),
          ],
          color: Colors.blue,
          width: 5,
        ),
      if (showDeadHeading &&
          (state.recentLocations.isNotEmpty &&
              (state.recentLocations.length >= 2) &&
              state.currentUserLocation != null))
        Polyline(
          points: [
            state.recentLocations.last,
            getNextPointOnLine(
              state.recentLocations[state.recentLocations.length - 2],
              state.recentLocations.last,
              Screen.width,
              Screen.height,
              state.currentZoom,
            ),
          ],
          color: Colors.red,
          width: 2,
          polylineId: const PolylineId('Dead Heading'),
        ),
    };
  }
}

class SpeedIndicator extends StatefulWidget {
  final double speedKmph;
  final Widget? child;

  const SpeedIndicator({super.key, required this.speedKmph, this.child});

  @override
  State<SpeedIndicator> createState() => _SpeedIndicatorState();
}

class _SpeedIndicatorState extends State<SpeedIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant SpeedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.speedKmph > 1.0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child:
          widget.child ??
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black38, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${widget.speedKmph.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
