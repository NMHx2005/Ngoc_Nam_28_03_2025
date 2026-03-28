# Đặt xe — IT3237 (Đề tài 10)

Ứng dụng Flutter: chọn điểm đón/đến trên bản đồ, tính giá, đặt chuyến, lưu Firestore, lịch sử chuyến. Backend: **Firebase Authentication** + **Cloud Firestore**. Bản đồ: **Google Maps**.

**Hướng dẫn setup từng bước (Firebase + Maps + billing + key):** xem [`HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md`](HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md).

**Git / GitHub (file mật không commit):** xem [`HUONG_DAN_GIT.md`](HUONG_DAN_GIT.md).

## Yêu cầu môi trường

- Flutter SDK (stable), Android Studio, Android SDK **API 24+**
- Tài khoản [Firebase Console](https://console.firebase.google.com/) và [Google Cloud Console](https://console.cloud.google.com/) (Maps API)

## Cấu hình bắt buộc trước khi chạy

### 1. Firebase — `google-services.json` (không commit)

1. Tạo project Firebase, bật **Authentication → Email/Password**.
2. Tạo **Firestore**, **Publish** rules (xem `firestore.rules`).
3. Thêm app Android package **`com.dongasia.it3237.ride_booking`**, tải `google-services.json` → đặt tại `android/app/google-services.json` (file này **bị `.gitignore`**; tham khảo `google-services.json.example`).

### 2. Google Maps — `api_keys.xml` (không commit)

1. Google Cloud: bật **Maps SDK for Android**, tạo API key (restrict Android + API).
2. Copy `android/app/src/main/res/values/api_keys.xml.example` → **`api_keys.xml`**, dán key vào `google_maps_key`.

### 3. Firestore rules

Copy nội dung `firestore.rules` vào Firebase Console → Firestore → Rules → Publish.

## Chạy app

```bash
cd ride_booking
flutter pub get
flutter run
```

## Kiểm thử

```bash
flutter test
```

## Cấu trúc `lib/`

| Thư mục | Nội dung |
|---------|----------|
| `core/` | Theme, hằng số, `distanceKm`, `PricingEngine` |
| `models/` | `Trip` |
| `data/repositories/` | `TripRepository` (Firestore) |
| `features/auth/` | Đăng nhập, đăng ký, `AuthGate` |
| `features/home/` | `HomeShell` (tab Bản đồ / Lịch sử) |
| `features/map_booking/` | Bản đồ, chọn điểm, đặt xe |
| `features/trip_history/` | Danh sách chuyến |
| `features/trip_detail/` | Chi tiết + nút giả lập trạng thái |

## Chức năng đã có / gợi ý mở rộng

- **Đã có:** Email đăng nhập/đăng ký, bản đồ, GPS, 2 marker, polyline thẳng, tính giá (giờ cao điểm), tạo chuyến Firestore, lịch sử, chi tiết chuyến, mock “tài xế nhận” / “hoàn thành”.
- **Có thể thêm:** Directions API (đường đi thật), thanh toán, thông báo, app phía tài xế, địa chỉ từ Places Autocomplete.

## Lưu ý bảo mật

Repo đã cấu hình `.gitignore` cho `google-services.json`, `api_keys.xml`, keystore, v.v. Xem [`HUONG_DAN_GIT.md`](HUONG_DAN_GIT.md). Nếu key đã lộ (chat, screenshot), **xoay key** trên Google Cloud / Firebase.
