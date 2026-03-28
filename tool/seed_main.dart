// ignore_for_file: avoid_print

// Seed chuyến mẫu lên Firestore (schema Trip). Chạy:
// flutter run -t tool/seed_main.dart --dart-define=SEED_EMAIL=a@b.com --dart-define=SEED_PASSWORD=matkhau
// Mỗi lần chạy thêm N document (không xóa dữ liệu cũ).

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ride_booking/models/trip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const email = String.fromEnvironment('SEED_EMAIL');
  const password = String.fromEnvironment('SEED_PASSWORD');

  runApp(_SeedRunner(email: email, password: password));
}

class _SeedRunner extends StatefulWidget {
  const _SeedRunner({required this.email, required this.password});

  final String email;
  final String password;

  @override
  State<_SeedRunner> createState() => _SeedRunnerState();
}

class _SeedRunnerState extends State<_SeedRunner> {
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (widget.email.isEmpty || widget.password.isEmpty) {
      setState(() {
        _error = true;
        _message =
            'Thiếu SEED_EMAIL / SEED_PASSWORD.\n\n'
            'Ví dụ:\n'
            'flutter run -t tool/seed_main.dart \\\n'
            '  --dart-define=SEED_EMAIL=ban@email.com \\\n'
            '  --dart-define=SEED_PASSWORD=matKhauCuaBan';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final raw = await rootBundle.loadString('seed/seed_trips.json');
      final decoded = jsonDecode(raw) as List<dynamic>;

      final batch = FirebaseFirestore.instance.batch();
      var count = 0;
      for (final item in decoded) {
        final m = Map<String, dynamic>.from(item as Map);
        final trip = Trip(
          userId: uid,
          pickupLat: (m['pickupLat'] as num).toDouble(),
          pickupLng: (m['pickupLng'] as num).toDouble(),
          dropoffLat: (m['dropoffLat'] as num).toDouble(),
          dropoffLng: (m['dropoffLng'] as num).toDouble(),
          distanceKm: (m['distanceKm'] as num).toDouble(),
          priceVnd: (m['priceVnd'] as num).toInt(),
          vehicleType: m['vehicleType'] as String,
          status: m['status'] as String,
          createdAt: DateTime.parse(m['createdAt'] as String).toUtc(),
          updatedAt: DateTime.parse(m['updatedAt'] as String).toUtc(),
        );
        final ref = FirebaseFirestore.instance.collection('trips').doc();
        batch.set(ref, trip.toMap());
        count++;
      }
      await batch.commit();

      print('Seed xong: đã thêm $count chuyến cho uid=$uid');
      if (mounted) {
        setState(() {
          _message =
              'Đã thêm $count chuyến mẫu.\n'
              'Dừng (Stop) và mở app bình thường → tab Lịch sử.';
        });
      }
    } catch (e, st) {
      print('Seed lỗi: $e\n$st');
      if (mounted) {
        setState(() {
          _error = true;
          _message = 'Lỗi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seed data',
      home: Scaffold(
        appBar: AppBar(title: const Text('Seed Firestore')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _message == null
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang đăng nhập và ghi dữ liệu…'),
                    ],
                  )
                : SelectableText(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error ? Colors.red : Colors.green.shade800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
