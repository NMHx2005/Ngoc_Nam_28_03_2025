import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// C4 — Tuỳ chọn: lấy lộ trình đường bộ qua **Directions API** (REST).
///
/// **Bật API:** Google Cloud Console → APIs & Services → bật *Directions API*.
/// **Key:** truyền `--dart-define=DIRECTIONS_API_KEY`; restrict phù hợp trên GCP.
///
/// Request mẫu (GET):
/// `https://maps.googleapis.com/maps/api/directions/json?origin=10.77,106.70&destination=10.79,106.71&mode=driving&key=YOUR_KEY`
///
/// Trả về JSON: `routes[0].overview_polyline.points` (chuỗi encoded) → decode thành danh sách [LatLng].
class DirectionsRouteService {
  DirectionsRouteService(this._apiKey);
  final String _apiKey;

  /// `null` nếu không có key, lỗi mạng, hoặc không có tuyến.
  Future<List<LatLng>?> fetchRoutePoints(LatLng origin, LatLng destination) async {
    if (_apiKey.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': _apiKey,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final overview = route['overview_polyline'] as Map<String, dynamic>?;
      final encoded = overview?['points'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      final decoded = PolylinePoints().decodePolyline(encoded);
      return decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (_) {
      return null;
    }
  }
}
