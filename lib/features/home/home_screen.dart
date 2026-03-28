import 'package:flutter/material.dart';

import 'home_shell.dart';

/// Màn chính sau đăng nhập (placeholder theo prompt B1 → thực tế là shell tab Bản đồ / Lịch sử).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeShell();
}
