import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_booking/core/geo/distance.dart';

void main() {
  test('distanceKm — hai điểm gần nhau > 0', () {
    const a = LatLng(10.7769, 106.7009);
    const b = LatLng(10.7879, 106.7109);
    final km = distanceKm(a, b);
    expect(km, greaterThan(0));
    expect(km, lessThan(50));
  });
}
