import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_adventures_admin/utils/styling/app_measurements.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_image.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

import '../../bloc/dive_sites.cubit.dart';
import 'close_region_compass.dart';
import 'location_error.dart';

class CloseRegionNavigationHelperScreen extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final bool isWidget;
  final String diveSiteName;

  const CloseRegionNavigationHelperScreen({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.isWidget,
    required this.diveSiteName,
  });

  static Route route({
    required double targetLatitude,
    required double targetLongitude,
    bool? isWidget,
    required String diveSite,
  }) => MaterialPageRoute(
    builder:
        (context) => CloseRegionNavigationHelperScreen(
          targetLatitude: targetLatitude,
          targetLongitude: targetLongitude,
          isWidget: isWidget ?? false,
          diveSiteName: diveSite,
        ),
  );

  @override
  State<CloseRegionNavigationHelperScreen> createState() => _CloseRegionNavigationHelperScreenState();
}

class _CloseRegionNavigationHelperScreenState extends State<CloseRegionNavigationHelperScreen> {
  final _locationStreamController = StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;
  late final CloseRegionCompass closeRegionCompass = CloseRegionCompass(widget.targetLatitude, widget.targetLongitude);

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    closeRegionCompass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return LoadingOverlay();
        if (snapshot.data!.enabled == true) {
          switch (snapshot.data!.status) {
            case LocationPermission.always:
            case LocationPermission.whileInUse:
              return _PointingArrow(closeRegionCompass, widget.isWidget);

            case LocationPermission.denied:
              return LocationErrorWidget(
                error: 'Location service permission denied',
                callback: _checkLocationStatus,
              );
            case LocationPermission.deniedForever:
              return LocationErrorWidget(
                error: 'Location service Denied Forever !',
                callback: _checkLocationStatus,
              );
            default:
              return const SizedBox();
          }
        } else {
          return LocationErrorWidget(
            error: 'Please enable Location service',
            callback: _checkLocationStatus,
          );
        }
      },
    );
    if (widget.isWidget) return child;

    return Scaffold(
      body: Stack(
        children: [
          BlocConsumer<DiveSiteCubit, DiveSiteState>(
            listener: (context, state) {},
            builder: (context, state) {
              final cubit = context.read<DiveSiteCubit>();

              final distance = cubit.distanceToSelectedSite;
              final speed = state.speed;

              // Color logic based on distance
              final Color color = () {
                if (distance < 0.1) return Colors.green;
                if (distance < 0.5) return Colors.red;
                if (distance < 1) return Colors.orange;
                return Colors.black;
              }();

              return AnimatedContainer(
                alignment: Alignment.center,
                color: color,
                padding: const EdgeInsets.all(8),
                duration: const Duration(milliseconds: 300),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          SafeArea(
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      if (distance < 0.1)
                        Text(
                          'Arrived !',
                          style: GoogleFonts.teko(
                            color: Colors.white,
                            fontSize: 40,
                          ),
                        ),

                      Row(
                        children: [
                          const Spacer(),
                          Opacity(
                            opacity: 0,
                            child: Text(
                              'KMPH',
                              style: GoogleFonts.teko(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ).paddingOnly(top: 40, right: 10),
                          ),
                          Text(
                            speed.toStringAsFixed(2),
                            style: GoogleFonts.teko(
                              color: Colors.white,
                              fontSize: 120,
                            ),
                          ),
                          Text(
                            'KMPH',
                            style: GoogleFonts.teko(
                              color: Colors.white70,
                              fontSize: 30,
                            ),
                          ).paddingOnly(top: 40, left: 10),
                          const Spacer(),
                        ],
                      ),

                      RichText(
                        text: TextSpan(
                          text: getReadableDistance(distance),
                          style: GoogleFonts.teko(
                            color: Colors.white,
                            fontSize: 40,
                          ),
                          children: const [
                            TextSpan(
                              text: ' to reach',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: ' dive site',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Spacing.h30,
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 130,
            child: SizedBox(
              width: Screen.width,
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }

  String getReadableDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} mts';
    }
    return '${distance.toStringAsFixed(1)} kms';
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await CloseRegionCompass.checkLocationStatus();
    if (locationStatus.enabled && locationStatus.status == LocationPermission.denied) {
      await CloseRegionCompass.requestPermissions();
      final s = await CloseRegionCompass.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else {
      _locationStreamController.sink.add(locationStatus);
    }
  }
}

class _PointingArrow extends StatelessWidget {
  final CloseRegionCompass closeRegionCompass;
  final bool showArrowOnly;

  const _PointingArrow(this.closeRegionCompass, this.showArrowOnly);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: closeRegionCompass.siteStream,
      builder: (_, AsyncSnapshot<Direction> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return LoadingOverlay();
        final siteDirection = snapshot.data!;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: (siteDirection.site * (pi / 180) * -1),
              alignment: Alignment.center,
              child: AppImage(
                'assets/images/needle.svg',
                width: 300,
                color: showArrowOnly ? Colors.black : Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
