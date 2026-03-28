import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

class RideBookingApp extends StatelessWidget {
  const RideBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đặt xe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // B2: `home` trỏ tới widget có StreamBuilder auth — không dùng go_router v.v.
      home: const AuthGate(),
    );
  }
}
