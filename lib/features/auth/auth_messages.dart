import 'package:firebase_auth/firebase_auth.dart';

String authMessageVi(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Email không hợp lệ.';
    case 'user-disabled':
      return 'Tài khoản đã bị khóa.';
    case 'user-not-found':
      return 'Không tìm thấy tài khoản.';
    case 'wrong-password':
      return 'Mật khẩu không đúng.';
    case 'email-already-in-use':
      return 'Email đã được đăng ký.';
    case 'weak-password':
      return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
    case 'invalid-credential':
      return 'Thông tin đăng nhập không hợp lệ.';
    case 'network-request-failed':
      return 'Lỗi mạng. Kiểm tra kết nối.';
    default:
      return e.message ?? 'Đã xảy ra lỗi (${e.code}).';
  }
}
