import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/trip.dart';
import '../trip_detail/trip_detail_screen.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  static Color _statusColor(String s) {
    switch (s) {
      case TripStatuses.findingDriver:
        return Colors.orange;
      case TripStatuses.accepted:
      case TripStatuses.inProgress:
        return Colors.blue;
      case TripStatuses.completed:
        return Colors.green;
      case TripStatuses.cancelled:
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  static String _statusShort(String s) {
    switch (s) {
      case TripStatuses.findingDriver:
        return 'Tìm xe';
      case TripStatuses.accepted:
        return 'Đã nhận';
      case TripStatuses.inProgress:
        return 'Đang đi';
      case TripStatuses.completed:
        return 'Xong';
      case TripStatuses.cancelled:
        return 'Hủy';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TripRepository>();

    return StreamBuilder<List<Trip>>(
      stream: repo.watchMyTrips(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data!;
        if (trips.isEmpty) {
          return const Center(child: Text('Chưa có chuyến nào.'));
        }
        return ListView.separated(
          itemCount: trips.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final t = trips[i];
            final time =
                '${t.createdAt.day}/${t.createdAt.month} ${t.createdAt.hour}:${t.createdAt.minute.toString().padLeft(2, '0')}';
            return ListTile(
              title: Text('$time · ${t.priceVnd} đ'),
              subtitle: Text(
                '${t.distanceKm.toStringAsFixed(1)} km · '
                '${t.pickupLat.toStringAsFixed(4)},… → ${t.dropoffLat.toStringAsFixed(4)},…',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(
                  _statusShort(t.status),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: _statusColor(t.status),
                padding: EdgeInsets.zero,
              ),
              onTap: () {
                final id = t.id;
                if (id == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => TripDetailScreen(tripId: id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
