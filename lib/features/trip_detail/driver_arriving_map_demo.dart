import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Bản đồ demo: marker xe di chuyển dọc đoạn [dropoff] → [pickup] (lặp lại).
class DriverArrivingMapDemo extends StatefulWidget {
  const DriverArrivingMapDemo({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  final LatLng pickup;
  final LatLng dropoff;

  @override
  State<DriverArrivingMapDemo> createState() => _DriverArrivingMapDemoState();
}

class _DriverArrivingMapDemoState extends State<DriverArrivingMapDemo>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _didFitCamera = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _anim.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static double _bearingDeg(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  /// Tiến độ 0..1: xe đi từ gần phía điểm đến về điểm đón.
  LatLng _carAt(double t) {
    const startU = 0.14;
    final u = startU + (1 - startU) * t;
    final p = widget.pickup;
    final d = widget.dropoff;
    return LatLng(
      d.latitude + (p.latitude - d.latitude) * u,
      d.longitude + (p.longitude - d.longitude) * u,
    );
  }

  void _tryFitCamera() {
    if (_didFitCamera || _mapController == null) return;
    final start = _carAt(0);
    final p = widget.pickup;
    final d = widget.dropoff;
    final minLat = math.min(math.min(start.latitude, p.latitude), d.latitude);
    final maxLat = math.max(math.max(start.latitude, p.latitude), d.latitude);
    final minLng = math.min(math.min(start.longitude, p.longitude), d.longitude);
    final maxLng = math.max(math.max(start.longitude, p.longitude), d.longitude);
    final padLat = math.max((maxLat - minLat) * 0.15, 0.002);
    final padLng = math.max((maxLng - minLng) * 0.15, 0.002);
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padLat, minLng - padLng),
      northeast: LatLng(maxLat + padLat, maxLng + padLng),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
    _didFitCamera = true;
  }

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(_anim.value);
    final car = _carAt(t);
    final bearing = _bearingDeg(car, widget.pickup);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Điểm đón của bạn'),
      ),
      Marker(
        markerId: const MarkerId('car'),
        position: car,
        rotation: bearing,
        flat: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Tài xế (demo)'),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('remaining'),
        color: Colors.blue.shade700,
        width: 4,
        patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        points: [car, widget.pickup],
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.pickup,
            zoom: 14,
          ),
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          onMapCreated: (c) {
            _mapController = c;
            WidgetsBinding.instance.addPostFrameCallback((_) => _tryFitCamera());
          },
        ),
      ),
    );
  }
}
