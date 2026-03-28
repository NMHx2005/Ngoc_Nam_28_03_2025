import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Khoảng cách chim bay giữa hai điểm (km). Đủ cho demo tính giá; khác đường đi thực tế.
double distanceKm(LatLng a, LatLng b) {
  final meters = Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
  return meters / 1000.0;
}
