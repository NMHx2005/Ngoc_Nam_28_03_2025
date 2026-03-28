import '../constants/app_constants.dart';

/// Động cơ tính giá VND — hằng số có thể chỉnh cho báo cáo.
class PricingEngine {
  PricingEngine._();

  static const int baseFareBike = 12000;
  static const int baseFareCar = 25000;
  static const int perKmBike = 5500;
  static const int perKmCar = 9500;
  static const double freeFirstKm = 0;
  static const double peakMultiplier = 1.2;

  static bool isPeakHour(DateTime now) {
    final h = now.hour;
    return (h >= 7 && h < 9) || (h >= 17 && h < 20);
  }

  /// Làm tròn lên bội số [step] VND (mặc định 500).
  static int calculate({
    required double distanceKm,
    required String vehicleType,
    required bool isPeakHour,
    int step = 500,
  }) {
    final base = vehicleType == VehicleTypes.car ? baseFareCar : baseFareBike;
    final perKm = vehicleType == VehicleTypes.car ? perKmCar : perKmBike;
    final billableKm = (distanceKm - freeFirstKm).clamp(0.0, double.infinity);
    var total = base + (billableKm * perKm).round();
    if (isPeakHour) {
      total = (total * peakMultiplier).round();
    }
    if (step <= 1) return total;
    final remainder = total % step;
    if (remainder == 0) return total;
    return total + (step - remainder);
  }
}
