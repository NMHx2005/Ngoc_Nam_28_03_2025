# Hướng dẫn Git & GitHub — ẩn file mật

Project đã cấu hình `.gitignore` để **không** đẩy lên remote các nội dung nhạy cảm.

---

## File / thư mục không lên Git (đã ignore)

| Mục | Lý do |
|-----|--------|
| `android/app/google-services.json` | Firebase: project id, API key, app id |
| `android/app/src/main/res/values/api_keys.xml` | Google Maps API key |
| `android/local.properties` | Đường dẫn SDK máy bạn |
| `android/key.properties`, `*.jks`, `*.keystore` | Ký bản release |
| `.env`, `.env.*` | Biến môi trường (nếu dùng sau này) |
| `build/`, `.dart_tool/`, … | Build & cache (chuẩn Flutter) |

**File mẫu được phép commit** (không chứa secret thật):

- `android/app/google-services.json.example`
- `android/app/api_keys.xml.example` (mẫu ngoài `res/` — tránh lỗi merge resource)

---

## Thành viên mới clone về máy

1. Copy `android/app/api_keys.xml.example` → `android/app/src/main/res/values/api_keys.xml`, dán **Maps API key**.
2. Tải `google-services.json` từ Firebase Console → đặt vào `android/app/`.
3. Chạy `flutter pub get` và `flutter run`.

---

## Khởi tạo repo & push lần đầu (máy đã có Git)

Trong thư mục `ride_booking`:

```bash
cd ride_booking
git init
git add .
git status
```

Kiểm tra **`git status`**: không thấy `google-services.json` và `api_keys.xml`. Nếu vẫn thấy (đã từng `git add` trước khi ignore), gỡ khỏi index:

```bash
git rm -r --cached android/app/google-services.json 2>/dev/null
git rm -r --cached android/app/src/main/res/values/api_keys.xml 2>/dev/null
git add .
```

Commit và gắn remote (thay URL repo của bạn):

```bash
git commit -m "Initial commit: ứng dụng đặt xe Flutter + Firebase"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

---

## Nếu đã lỡ commit secret lên GitHub

1. **Đổi / xoay** ngay: Maps API key (Credentials), Firebase key trong Console nếu cần.
2. Xóa file khỏi **toàn bộ lịch sử** là việc nâng cao (`git filter-repo` / BFG) — nên nhờ người quen Git hoặc tạo **repo mới** + commit sạch từ bản đã `.gitignore` đúng.

---

## Gợi ý README trên GitHub

Ghi rõ: *“Sao chép `android/app/api_keys.xml.example` → `res/values/api_keys.xml` và thêm `google-services.json` theo `HUONG_DAN_SETUP_FIREBASE_VA_MAPS.md`.”*

---

*Tài liệu nội bộ nhóm IT3237.*
