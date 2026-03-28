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
}
