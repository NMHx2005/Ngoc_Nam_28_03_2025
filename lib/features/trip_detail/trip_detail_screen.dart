import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/trip.dart';
import 'driver_arriving_map_demo.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  static String _statusLabel(String s) {
    switch (s) {
      case TripStatuses.findingDriver:
        return 'Đang tìm tài xế';
      case TripStatuses.accepted:
        return 'Tài xế đã nhận';
      case TripStatuses.driverArriving:
        return 'Tài xế đang đến điểm đón';
      case TripStatuses.inProgress:
        return 'Đang di chuyển tới điểm đến';
      case TripStatuses.completed:
        return 'Hoàn thành';
      case TripStatuses.cancelled:
        return 'Đã hủy';
      default:
        return s;
    }
  }

  static String _vehicleLabel(String v) {
    return v == VehicleTypes.car ? 'Ô tô' : 'Xe máy';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TripRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chuyến')),
      body: StreamBuilder<Trip?>(
        stream: repo.watchTrip(tripId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final trip = snapshot.data;
          if (trip == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                title: const Text('Mã chuyến'),
                subtitle: SelectableText(trip.id ?? tripId),
              ),
              ListTile(
                title: const Text('Trạng thái'),
                subtitle: Text(_statusLabel(trip.status)),
              ),
              if (trip.status == TripStatuses.driverArriving ||
                  trip.status == TripStatuses.accepted) ...[
                DriverArrivingMapDemo(
                  key: ValueKey(
                    '${trip.pickupLat}_${trip.pickupLng}_'
                    '${trip.dropoffLat}_${trip.dropoffLng}',
                  ),
                  pickup: LatLng(trip.pickupLat, trip.pickupLng),
                  dropoff: LatLng(trip.dropoffLat, trip.dropoffLng),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vị trí xe (demo, lặp lại)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_filled,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            trip.status == TripStatuses.driverArriving
                                ? 'Demo: tài xế đã nhận cuốc và đang di chuyển tới chỗ bạn.'
                                : 'Demo: chuyến đã được nhận; có thể bấm bước tiếp theo để mô phỏng tài xế tới điểm đón.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ListTile(
                title: const Text('Loại xe'),
                subtitle: Text(_vehicleLabel(trip.vehicleType)),
              ),
              ListTile(
                title: const Text('Khoảng cách'),
                subtitle: Text('${trip.distanceKm.toStringAsFixed(2)} km'),
              ),
              ListTile(
                title: const Text('Giá'),
                subtitle: Text('${trip.priceVnd.toString()} đ'),
              ),
              ListTile(
                title: const Text('Điểm đón'),
                subtitle: Text(
                  '${trip.pickupLat.toStringAsFixed(5)}, ${trip.pickupLng.toStringAsFixed(5)}',
                ),
              ),
              ListTile(
                title: const Text('Điểm đến'),
                subtitle: Text(
                  '${trip.dropoffLat.toStringAsFixed(5)}, ${trip.dropoffLng.toStringAsFixed(5)}',
                ),
              ),
              const SizedBox(height: 16),
              if (trip.status == TripStatuses.findingDriver)
                FilledButton(
                  onPressed: () async {
                    await repo.updateStatus(
                      tripId,
                      TripStatuses.driverArriving,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tài xế đã nhận chuyến — đang đến điểm đón (demo).',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Giả lập: tài xế nhận & đang đến'),
                ),
              if (trip.status == TripStatuses.driverArriving ||
                  trip.status == TripStatuses.accepted) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    await repo.updateStatus(tripId, TripStatuses.inProgress);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã đón khách — đang di chuyển tới điểm đến (demo).',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Giả lập: đã đến đón — bắt đầu chuyến'),
                ),
              ],
              if (trip.status == TripStatuses.inProgress) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => repo.updateStatus(
                    tripId,
                    TripStatuses.completed,
                  ),
                  child: const Text('Giả lập: hoàn thành chuyến'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
