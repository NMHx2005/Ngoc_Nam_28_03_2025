# Ứng dụng đặt xe — Đồ án IT3237 (Đề tài 10)

## 1. Mô tả đề tài

Đề tài xây dựng **ứng dụng di động đặt chuyến xe** trên nền **Flutter**, phục vụ người dùng cuối: xác định điểm đón và điểm đến trên **Google Maps**, ước lượng khoảng cách (Haversine), tính **giá VND** theo quy tắc nghiệp vụ mẫu, tạo **chuyến đi** lưu trên **Cloud Firestore**, theo dõi **trạng thái chuyến** (demo) và xem **lịch sử chuyến** theo thời gian thực. Xác thực người dùng dùng **Firebase Authentication** (email/mật khẩu).

Ứng dụng nhằm minh họa luồng nghiệp vụ end-to-end của một hệ thống gọi xe đơn giản, không triển khai ứng dụng phía tài xế hay cổng thanh toán thực tế.

### Ảnh demo (placeholder)

Khi nộp báo cáo hoặc đẩy lên GitHub, nên thay ảnh dưới bằng **screenshot thật** (màn đăng nhập, bản đồ, sheet đặt xe, lịch sử).

<p align="center">
  <img src="https://via.placeholder.com/360x780/e8eaf0/37474f?text=Screenshot%3A+Ban+do+%2B+dat+xe" width="260" alt="Placeholder ảnh demo — thay bằng ảnh chụp màn hình ứng dụng"/>
</p>

---

## 2. Yêu cầu môi trường

| Thành phần | Ghi chú |
|------------|---------|
| **Flutter SDK** | Kênh *stable*, tương thích **Dart ^3.11** (theo `pubspec.yaml`) |
| **Android Studio** / SDK | **minSdk 24** (`android/app/build.gradle.kts`), thiết bị ảo hoặc máy thật bật USB debugging |
| **Tài khoản Google** | [Firebase Console](https://console.firebase.google.com/) (Auth + Firestore), [Google Cloud Console](https://console.cloud.google.com/) (bật Maps SDK for Android, tuỳ chọn Directions API) |

Có thể chạy thêm trên **iOS / macOS / Windows / Linux** nhờ khung đa nền tảng của Flutter; hướng dẫn dưới đây tập trung **Android** (cấu hình Firebase + Maps đã gắn với module `android/`).

---

## 3. Lấy `google-services.json` và API key (không đưa secret vào repo)

**Nguyên tắc:** không commit file chứa khóa thật. Repo đã `.gitignore` các file nhạy cảm; chỉ giữ file **mẫu** (`.example`) để tham chiếu cấu trúc.

### 3.1. `google-services.json` (Firebase Android)

1. Vào Firebase Console → tạo hoặc chọn project.
2. Thêm ứng dụng **Android** với **applicationId** trùng `com.dongasia.it3237.ride_booking` (xem `android/app/build.gradle.kts`).
3. Tải file **`google-services.json`** do Firebase cung cấp.
4. Đặt file tại: **`android/app/google-services.json`** (cùng cấp với file mẫu `google-services.json.example`).

File này chứa metadata project Firebase; **không** dán nội dung vào README và **không** push lên Git công khai.

### 3.2. API key Google Maps (Android)

1. Trong Google Cloud (cùng project hoặc liên kết với Firebase), bật **Maps SDK for Android**.
2. Tạo **API key**, cấu hình hạn chế (ứng dụng Android + giới hạn API) theo chính sách của nhà trường / đồ án.
3. Sao chép `android/app/api_keys.xml.example` thành **`android/app/src/main/res/values/api_keys.xml`**, điền key vào placeholder (file `.example` nằm **ngoài** `res/` để Gradle không báo lỗi tên file).

Tương tự, **không** commit `api_keys.xml` thật.

### 3.3. Tuỳ chọn: Directions API (lộ trình đường bộ)

Để vẽ polyline theo đường đi thay cho đoạn thẳng, khi chạy có thể truyền (không hard-code trong mã nguồn):

```bash
flutter run --dart-define=DIRECTIONS_API_KEY=YOUR_KEY_HERE
```

Cần bật **Directions API** trên Google Cloud và hạn chế key phù hợp.

**Chi tiết từng bước (billing, rule Firestore, v.v.):** [`HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md`](HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md).

**Git / GitHub, file mật:** [`HUONG_DAN_GIT.md`](HUONG_DAN_GIT.md).

---

## 4. Cấu hình Firestore

Sao chép nội dung **`firestore.rules`** trong repo lên Firebase Console → Firestore → **Rules** → **Publish** (đảm bảo user chỉ đọc/ghi dữ liệu phù hợp với luồng demo).

---

## 5. Lệnh chạy ứng dụng

Trong thư mục gốc project Flutter (`ride_booking/`):

```bash
flutter pub get
flutter run
```

Kiểm thử đơn vị / widget (nếu cần):

```bash
flutter test
```

### 5.1. Dữ liệu mẫu (seed) trên Firestore

Cần tài khoản **đã đăng ký** trên Firebase Auth (cùng project với app). Mỗi lần chạy **thêm** 6 chuyến mẫu vào collection `trips` (không xóa chuyến cũ).

```bash
flutter run -t tool/seed_main.dart \
  --dart-define=SEED_EMAIL=email_da_dang_ky@example.com \
  --dart-define=SEED_PASSWORD=mat_khau_cua_ban
```

Chờ màn hình báo thành công → **Stop** → chạy lại app bình thường (`flutter run` hoặc `lib/main.dart`) → tab **Lịch sử**.

File dữ liệu JSON có thể sửa tại **`seed/seed_trips.json`** (tọa độ khu vực TP.HCM mẫu, nhiều trạng thái: `completed`, `driver_arriving`, `finding_driver`, `cancelled`, `in_progress`).

---

## 6. Cấu trúc thư mục (rút gọn)

```
ride_booking/
├── android/                 # Cấu hình Gradle Kotlin DSL, google-services plugin
│   └── app/
│       ├── google-services.json      # Tạo cục bộ — không commit
│       ├── api_keys.xml.example      # Mẫu (commit được) — copy → res/values/api_keys.xml
│       └── src/main/res/values/
│           └── api_keys.xml          # Tạo cục bộ — không commit
├── lib/
│   ├── main.dart, app.dart
│   ├── core/                # Theme, hằng số, Haversine, PricingEngine
│   ├── models/              # Trip
│   ├── data/repositories/   # TripRepository (Firestore)
│   └── features/
│       ├── auth/            # Đăng nhập, đăng ký, AuthGate, validator
│       ├── home/            # HomeShell — tab Bản đồ / Lịch sử
│       ├── map_booking/     # Bản đồ, chọn điểm, sheet đặt xe, polyline
│       ├── trip_history/    # Stream danh sách chuyến
│       └── trip_detail/     # Chi tiết + nút giả lập trạng thái
├── seed/
│   └── seed_trips.json      # Mẫu import qua tool/seed_main.dart
├── tool/
│   └── seed_main.dart       # Entry seed Firestore (email/MK qua --dart-define)
├── test/                    # Test khoảng cách, giá, model Trip, polyline
├── firestore.rules
├── pubspec.yaml
├── README.md
├── HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md
└── HUONG_DAN_GIT.md
```

---

## 7. Chức năng đã triển khai / chưa có

### Đã triển khai

- Đăng ký / đăng nhập **email + mật khẩu**, validate form, `AuthGate` điều hướng.
- **Bản đồ** Google Maps, quyền vị trí, **chọn điểm đón / điểm đến bằng chạm bản đồ**, marker tương ứng (xanh / đỏ), polyline mặc định **đoạn thẳng**; tuỳ chọn **Directions API** qua `--dart-define`.
- Tính **khoảng cách** Haversine; **giá VND** (mở cửa, km, km đầu miễn phí, giờ cao điểm, làm tròn bội số).
- **Đặt chuyến:** bottom sheet xác nhận, `createTrip` trạng thái `finding_driver`, chuyển màn chi tiết; chống double submit / hiển thị loading.
- **Chi tiết chuyến:** stream Firestore, giả lập **nhận chuyến → đang đến điểm đón → bắt đầu chuyến → hoàn thành** (nút bấm theo từng bước).
- **Lịch sử chuyến:** `StreamBuilder` + danh sách, tap mở chi tiết.
- **Đăng xuất** từ AppBar tab chính.

### Chưa triển khai / ngoài phạm vi đồ án hiện tại

- Ứng dụng **tài xế** thật, phân phối chuyến, chat.
- **Thanh toán** (ví, thẻ, ví điện tử).
- **Thông báo đẩy** (FCM) khi có tài xế / hết thời gian chờ.
- **Đánh giá** sau chuyến, khuyến mãi, nhiều loại dịch vụ.
- Triển khai đầy đủ **iOS** (Maps + Firebase) nếu chưa cấu hình `GoogleService-Info.plist` và key tương ứng.
- **Tìm địa chỉ bằng văn bản** (Places / Geocoding) — đã bỏ khỏi bản demo; chỉ chọn tọa độ trên bản đồ.

---

## 8. Bảo mật và học thuật

Nếu lỡ lộ API key hoặc `google-services.json` (chat, screenshot công khai), cần **xoay / thu hồi** key trên Google Cloud và tạo lại file cấu hình. README và tài liệu kèm theo chỉ mô tả **cách** lấy secret, không nhúng giá trị thật.

---

*Tài liệu này phục vụ clone repo, cấu hình môi trường và vấn đáp; chi tiết kỹ thuật bổ sung nằm trong mã nguồn và các file `HUONG_DAN_*.md`.*
