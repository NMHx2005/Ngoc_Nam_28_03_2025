import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_booking/core/geo/distance.dart';

void main() {
  test('distanceKm — cùng một điểm = 0', () {
    const p = LatLng(10.7769, 106.7009);
    expect(distanceKm(p, p), 0.0);
  });

  /// Trên xích đạo, 1° kinh độ ≈ π/180 * R km ≈ 111,195 km (đường chim bay).
  test('distanceKm — xích đạo 1° kinh độ ≈ 111,2 km', () {
    const a = LatLng(0, 0);
    const b = LatLng(0, 1);
    final km = distanceKm(a, b);
    expect(km, closeTo(111.195, 0.05));
  });

  test('distanceKm — hai điểm TP.HCM lân cận, dương và hợp lý', () {
    const a = LatLng(10.7769, 106.7009);
    const b = LatLng(10.7879, 106.7109);
    final km = distanceKm(a, b);
    expect(km, greaterThan(0));
    expect(km, lessThan(50));
  });
}
