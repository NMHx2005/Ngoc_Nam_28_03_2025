import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  static String _statusLabel(String s) {
    switch (s) {
      case TripStatuses.findingDriver:
        return 'Đang tìm tài xế';
      case TripStatuses.accepted:
        return 'Tài xế đã nhận';
      case TripStatuses.inProgress:
        return 'Đang di chuyển';
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
                    await repo.updateStatus(tripId, TripStatuses.accepted);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã giả lập tài xế nhận chuyến.')),
                      );
                    }
                  },
                  child: const Text('Giả lập: tài xế nhận'),
                ),
              if (trip.status == TripStatuses.accepted) ...[
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
