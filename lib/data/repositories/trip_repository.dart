import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/trip.dart';

class TripRepository {
  TripRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  Future<String> createTrip(Trip trip) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || trip.userId != uid) {
      throw StateError('Chưa đăng nhập hoặc userId không khớp.');
    }
    final doc = await _trips.add(trip.toCreateMap());
    return doc.id;
  }

  /// Luồng chuyến của user [uid], mới nhất trước (sort client-side, không cần index phức tạp).
  Stream<List<Trip>> watchMyTrips(String uid) {
    final current = _auth.currentUser?.uid;
    if (current == null || current != uid) {
      return const Stream.empty();
    }
    return _trips.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Trip.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<Trip?> watchTrip(String tripId) {
    return _trips.doc(tripId).snapshots().map((d) {
      if (!d.exists || d.data() == null) return null;
      return Trip.fromDoc(d);
    });
  }

  Future<void> updateStatus(String tripId, String status) {
    return _trips.doc(tripId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
