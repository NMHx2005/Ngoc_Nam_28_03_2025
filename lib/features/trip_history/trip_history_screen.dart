import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/trip.dart';
import '../trip_detail/trip_detail_screen.dart';

/// E1: stream chuyến của user — ListView, tap → chi tiết.
class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  static Color _statusColor(String s) {
    switch (s) {
      case TripStatuses.findingDriver:
        return Colors.orange.shade700;
      case TripStatuses.accepted:
      case TripStatuses.driverArriving:
      case TripStatuses.inProgress:
        return Colors.blue.shade700;
      case TripStatuses.completed:
        return Colors.green.shade700;
      case TripStatuses.cancelled:
        return Colors.blueGrey.shade600;
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
      case TripStatuses.driverArriving:
        return 'Đang đến';
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

  /// Tọa độ rút gọn (4 chữ số thập phân).
  static String _shortCoord(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  static String _formatVnd(int v) {
    final s = v.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  static String _formatTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TripRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Chưa đăng nhập.'));
    }

    return StreamBuilder<List<Trip>>(
      stream: repo.watchMyTrips(uid),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final t = trips[i];
            final id = t.id;
            final theme = Theme.of(context);

            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: id == null
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => TripDetailScreen(tripId: id),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(t.createdAt),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(
                              _statusShort(t.status),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: _statusColor(t.status),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đón ${_shortCoord(t.pickupLat, t.pickupLng)}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Đến ${_shortCoord(t.dropoffLat, t.dropoffLng)}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t.distanceKm.toStringAsFixed(1)} km · ${_formatVnd(t.priceVnd)} đ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
