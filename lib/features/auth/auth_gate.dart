import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'login_screen.dart';

/// Cổng điều hướng theo phiên đăng nhập Firebase.
///
/// Dùng [FirebaseAuth.authStateChanges] vì mỗi khi đăng nhập/đăng xuất/session hết hạn,
/// Firebase phát sự kiện mới — UI tự đồng bộ, không cần gọi Navigator thủ công.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
