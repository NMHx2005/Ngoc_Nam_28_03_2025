import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_booking/models/trip.dart';

void main() {
  test('Trip fromMap / toMap — roundtrip field', () {
    final t0 = Trip(
      id: 'abc',
      userId: 'u1',
      pickupLat: 10.1,
      pickupLng: 106.1,
      dropoffLat: 10.2,
      dropoffLng: 106.2,
      distanceKm: 1.5,
      priceVnd: 50000,
      vehicleType: 'bike',
      status: 'finding_driver',
      createdAt: DateTime.utc(2026, 3, 28, 10, 0),
      updatedAt: DateTime.utc(2026, 3, 28, 10, 1),
    );
    final m = t0.toMap();
    final t1 = Trip.fromMap('abc', m);
    expect(t1.userId, t0.userId);
    expect(t1.pickupLat, t0.pickupLat);
    expect(t1.priceVnd, t0.priceVnd);
    expect(t1.createdAt.toUtc(), t0.createdAt);
    expect(t1.updatedAt.toUtc(), t0.updatedAt);
    expect(m['createdAt'], isA<Timestamp>());
  });
}
