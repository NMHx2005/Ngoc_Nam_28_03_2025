import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Động cơ tính giá VND — công thức mẫu cho báo cáo (hằng số có thể chỉnh).
///
/// Công thức: `tổng = (giá mở cửa + km tính phí × đơn giá/km)` × hệ số giờ cao điểm (nếu có),
/// rồi **làm tròn lên** bội số [step] (500 hoặc 1000 VND).
class PricingEngine {
  PricingEngine._();

  // --- Hằng số (tiếng Việt, dễ đưa vào Chương 2 báo cáo) ---

  static const int giaMoCuaXeMay = 12000;
  static const int giaMoCuaOTo = 25000;
  static const int donGiaMoiKmXeMay = 5500;
  static const int donGiaMoiKmOTo = 9500;

  /// Số km đầu **không** tính tiền (0 = tắt; có thể đặt 1 để demo “km đầu miễn phí”).
  static const double kmDauDuocMienPhi = 1.0;

  static const double heSoGioCaoDiem = 1.2;

  static bool isPeakHour(DateTime now) {
    final h = now.hour;
    return (h >= 7 && h < 9) || (h >= 17 && h < 20);
  }

  /// [step]: bội số làm tròn (500 hoặc 1000 VND).
  static int calculate({
    required double distanceKm,
    required String vehicleType,
    required bool isPeakHour,
    int step = 500,
  }) {
    final laOTo = vehicleType == VehicleTypes.car;
    final giaMoCua = laOTo ? giaMoCuaOTo : giaMoCuaXeMay;
    final donGiaMoiKm = laOTo ? donGiaMoiKmOTo : donGiaMoiKmXeMay;

    final soKmTinhPhi = (distanceKm - kmDauDuocMienPhi)
        .clamp(0.0, double.infinity);

    var tongTruocLamTron =
        giaMoCua + (soKmTinhPhi * donGiaMoiKm).round();

    if (isPeakHour) {
      tongTruocLamTron = (tongTruocLamTron * heSoGioCaoDiem).round();
    }

    return _lamTronLenBoSo(tongTruocLamTron, step);
  }

  static int _lamTronLenBoSo(int soTien, int buoc) {
    if (buoc <= 1) return soTien;
    final du = soTien % buoc;
    if (du == 0) return soTien;
    return soTien + (buoc - du);
  }

  /// Ba ví dụ in ra console (chỉ **debug**): chuyến ngắn, chuyến dài, giờ cao điểm.
  /// Chạy `flutter run` và xem log để chụp ảnh minh chứng báo cáo.
  static void inViDuRaConsole() {
    if (!kDebugMode) return;

    final giaNgan = calculate(
      distanceKm: 0.8,
      vehicleType: VehicleTypes.bike,
      isPeakHour: false,
    );
    final giaDai = calculate(
      distanceKm: 12,
      vehicleType: VehicleTypes.car,
      isPeakHour: false,
    );
    final giaCaoDiem = calculate(
      distanceKm: 3,
      vehicleType: VehicleTypes.bike,
      isPeakHour: true,
    );

    debugPrint('========== [PricingEngine] Ví dụ tính giá ==========');
    debugPrint(
      '1) Chuyến ngắn — 0,8 km, xe máy, không giờ cao điểm: $giaNgan đ',
    );
    debugPrint(
      '2) Chuyến dài — 12 km, ô tô, không giờ cao điểm: $giaDai đ',
    );
    debugPrint(
      '3) Giờ cao điểm — 3 km, xe máy (+${((heSoGioCaoDiem - 1) * 100).toInt()}%): $giaCaoDiem đ',
    );
    debugPrint('   (km đầu miễn phí: $kmDauDuocMienPhi km; làm tròn bội 500 đ)');
    debugPrint('====================================================');
  }
}
