/// Validate dùng chung Login / Register.
abstract class AuthValidators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập email';
    final t = v.trim();
    final ok = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(t);
    if (!ok) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }
    return null;
  }
}
