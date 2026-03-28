import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// C4 — Fallback bắt buộc: đường thẳng nối pickup → dropoff (không tốn Directions API).
Polyline buildStraightRoutePolyline({
  required LatLng pickup,
  required LatLng dropoff,
  Color color = const Color(0xFF1565C0),
  int width = 4,
}) {
  return Polyline(
    polylineId: const PolylineId('straight'),
    color: color,
    width: width,
    points: [pickup, dropoff],
  );
}
