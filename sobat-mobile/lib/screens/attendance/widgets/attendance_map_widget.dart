import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapcn_flutter/mapcn_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/theme.dart';

class AttendanceMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<dynamic> locations;
  final String matchedLocationName;
  final Position? currentPosition;
  final AnimationController pulseController;
  final Animation<double> pulseAnimation;

  const AttendanceMapWidget({
    super.key,
    required this.mapController,
    required this.locations,
    required this.matchedLocationName,
    required this.currentPosition,
    required this.pulseController,
    required this.pulseAnimation,
  });

  IconData _getLocationIcon(String locationId) {
    return switch (locationId) {
      'office' => Icons.business,
      'gudang_b3' => Icons.warehouse,
      'training_centre' => Icons.school,
      _ => Icons.location_on,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(
          (locations.first['latitude'] as num).toDouble(),
          (locations.first['longitude'] as num).toDouble(),
        ),
        initialZoom: 16.0,
      ),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(MapcnThemes.midnight),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sobat_hr',
          ),
        ),
        CircleLayer(
          circles: [
            for (final loc in locations)
              CircleMarker(
                point: LatLng(
                  (loc['latitude'] as num).toDouble(),
                  (loc['longitude'] as num).toDouble(),
                ),
                color: (loc['name'] == matchedLocationName)
                    ? Colors.green.withValues(alpha: 0.2)
                    : AppTheme.colorCyan.withValues(alpha: 0.15),
                borderColor: (loc['name'] == matchedLocationName)
                    ? Colors.green
                    : AppTheme.colorCyan,
                borderStrokeWidth: (loc['name'] == matchedLocationName) ? 2 : 1,
                useRadiusInMeter: true,
                radius: (loc['radius_meters'] as num?)?.toDouble() ?? 100.0,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final loc in locations)
              Marker(
                point: LatLng(
                  (loc['latitude'] as num).toDouble(),
                  (loc['longitude'] as num).toDouble(),
                ),
                width: 80,
                height: 70,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (loc['name'] == matchedLocationName)
                            ? Colors.green
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(
                        loc['name'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: (loc['name'] == matchedLocationName)
                              ? Colors.white
                              : AppTheme.colorEggplant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: Icon(
                        _getLocationIcon(loc['id'] as String? ?? ''),
                        color: (loc['name'] == matchedLocationName)
                            ? Colors.green
                            : AppTheme.colorEggplant,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            if (currentPosition != null)
              Marker(
                point: LatLng(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                ),
                width: 100,
                height: 100,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40 * pulseAnimation.value,
                          height: 40 * pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.cyanAccent.withValues(
                              alpha: 0.4 - (pulseController.value * 0.4),
                            ),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.cyanAccent,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
