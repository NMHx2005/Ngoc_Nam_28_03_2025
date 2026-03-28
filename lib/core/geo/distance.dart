import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Bán kính Trái Đất trung bình (km) — dùng trong haversine.
const double _earthRadiusKm = 6371.0;

double _toRad(double degrees) => degrees * math.pi / 180;

/// Khoảng cách **đường chim bay** giữa hai điểm (km), công thức **haversine**
/// trên mô hình cầu (WGS84 gần đúng).
///
/// **Đủ cho đồ án / demo tính giá:** code gọn, không gọi API, phản ánh “xa–gần” hợp lý.
/// **Khác đường bộ thực tế:** xe phải theo đường phố, một chiều, vòng tránh — quãng đường
/// Directions thường **dài hơn** chim bay; trong đô thị chênh lệch có khi vài chục %.
/// Muốn giá sát thực tế cần lấy `distanceMeters` từ Directions hoặc tương đương.
double distanceKm(LatLng a, LatLng b) {
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);

  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);
  final h = sinDLat * sinDLat +
      math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return _earthRadiusKm * c;
}
