import 'package:cloud_firestore/cloud_firestore.dart';

/// Model chuyến đặt xe — mapping thủ công (không freezed).
///
/// - `toCreateMap()`: tạo document mới (`FieldValue.serverTimestamp`).
/// - `toMap()`: map đầy đủ sau khi đã có thời gian (đọc được / minh họa).
/// - `fromMap` / `fromDoc`: đọc từ Firestore.
class Trip {
  const Trip({
    this.id,
    required this.userId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.distanceKm,
    required this.priceVnd,
    required this.vehicleType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String userId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double distanceKm;
  final int priceVnd;
  final String vehicleType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ghi document mới — `createdAt` / `updatedAt` do server gán.
  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'distanceKm': distanceKm,
      'priceVnd': priceVnd,
      'vehicleType': vehicleType,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map field đầy đủ (dùng [Timestamp] cho thời gian).
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'distanceKm': distanceKm,
      'priceVnd': priceVnd,
      'vehicleType': vehicleType,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Trip fromMap(String documentId, Map<String, dynamic> d) {
    return Trip(
      id: documentId,
      userId: d['userId'] as String,
      pickupLat: (d['pickupLat'] as num).toDouble(),
      pickupLng: (d['pickupLng'] as num).toDouble(),
      dropoffLat: (d['dropoffLat'] as num).toDouble(),
      dropoffLng: (d['dropoffLng'] as num).toDouble(),
      distanceKm: (d['distanceKm'] as num).toDouble(),
      priceVnd: (d['priceVnd'] as num).toInt(),
      vehicleType: d['vehicleType'] as String,
      status: d['status'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  static Trip fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data()!);
  }
}
