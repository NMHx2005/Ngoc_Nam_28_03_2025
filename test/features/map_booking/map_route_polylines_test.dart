import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_booking/features/map_booking/map_route_polylines.dart';

void main() {
  test('buildStraightRoutePolyline — hai điểm', () {
    const a = LatLng(10.77, 106.70);
    const b = LatLng(10.79, 106.72);
    final p = buildStraightRoutePolyline(pickup: a, dropoff: b);
    expect(p.points, [a, b]);
    expect(p.polylineId.value, 'straight');
  });
}
