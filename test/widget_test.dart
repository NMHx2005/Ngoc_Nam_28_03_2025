import 'package:flutter_test/flutter_test.dart';
import 'package:ride_booking/core/constants/app_constants.dart';
import 'package:ride_booking/core/pricing/pricing_engine.dart';

void main() {
  test('PricingEngine — giá là bội số 500 VND', () {
    final p = PricingEngine.calculate(
      distanceKm: 2.5,
      vehicleType: VehicleTypes.bike,
      isPeakHour: false,
    );
    expect(p % 500, 0);
    expect(p, greaterThan(0));
  });

  test('PricingEngine — làm tròn bội 1000', () {
    final p = PricingEngine.calculate(
      distanceKm: 1,
      vehicleType: VehicleTypes.bike,
      isPeakHour: false,
      step: 1000,
    );
    expect(p % 1000, 0);
  });

  test('PricingEngine — có km đầu miễn phí: 2,5 km xe máy tương đương ~1,5 km tính phí', () {
    // 12000 + 1.5*5500 = 20250 → làm tròn 500 → 20500
    final p = PricingEngine.calculate(
      distanceKm: 2.5,
      vehicleType: VehicleTypes.bike,
      isPeakHour: false,
    );
    expect(p, 20500);
  });
}
