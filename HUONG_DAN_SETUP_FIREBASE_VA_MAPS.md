# Hướng dẫn setup chi tiết — Firebase & Google Maps (Android)

Tài liệu dành cho project **ride_booking** (Flutter). **Package Android bắt buộc trùng khớp:**

`com.dongasia.it3237.ride_booking`

---

## Phần A — Firebase

### A1. Tạo project Firebase

1. Vào [Firebase Console](https://console.firebase.google.com/).
2. **Add project** → đặt tên (ví dụ: đồ án đặt xe) → tắt/bật Analytics tùy nhóm → **Create project**.

### A2. Thêm ứng dụng Android

1. Trang **Project overview**, chọn biểu tượng **Android** (hoặc **Add app** → Android).
2. **Android package name:** nhập chính xác  
   `com.dongasia.it3237.ride_booking`
3. App nickname: tùy (ví dụ `Ride Booking Android`).
4. **Debug signing certificate SHA-1** (tùy chọn ngay bước này):  
   - Với **Email/Password** thì **không bắt buộc** ngay lúc đầu.  
   - Nếu sau này dùng **Google Sign-In** hoặc giới hạn API key theo SHA-1 thì cần thêm SHA-1 trong Firebase (Project settings → Your apps → Add fingerprint).

**Lấy SHA-1 debug (khi cần):**

File ký **debug** mặc định nằm tại `~/.android/debug.keystore` (Windows: `%USERPROFILE%\.android\debug.keystore`). Nếu chưa có, chạy **`flutter run`** lên thiết bị/emulator **Android** một lần (hoặc `flutter build apk --debug`) để hệ thống tạo keystore.

---

**Cách 1 — `keytool` (khuyến nghị khi máy chỉ có JDK 17)**

`keytool` đi kèm JDK 17; **không** phụ thuộc phiên bản JVM mà Gradle yêu cầu (Gradle/AGP đôi khi bắt chạy bằng **JDK 21**, nhưng bytecode app vẫn target **Java 17** trong `android/app/build.gradle.kts`).

*Tìm dòng **SHA1:** trong output và copy chuỗi `AA:BB:...`.*

**Windows (PowerShell)** — có thể chạy ở bất kỳ thư mục nào:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Nếu `keytool` không có trong PATH, dùng JDK đã cài (ví dụ Android Studio `jbr`):

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**macOS / Linux:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

**Cách 2 — Gradle `signingReport`**

Bản **Gradle** kèm project có thể yêu cầu **JDK 21** để chạy lệnh; nếu máy chỉ có JDK 17 và lệnh báo lỗi JVM, dùng **Cách 1**.

**macOS / Linux** (trong thư mục `android`):

```bash
cd android
./gradlew signingReport
```

**Windows** (PowerShell, **đang đứng trong** thư mục `android` của project):

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
.\gradlew.bat signingReport
```

(Sửa đường dẫn `JAVA_HOME` nếu Android Studio cài chỗ khác; hoặc trỏ tới JDK 21 nếu Gradle yêu cầu.)

Tìm mục **Variant: debug** → copy dòng **SHA1** (dạng `AA:BB:...`).

5. **Register app** → **Download `google-services.json`**.

### A3. Đặt file vào project Flutter

1. Copy file vừa tải vào:

   `android/app/google-services.json`

2. **Ghi đè** file cũ (nếu có). File này **không** commit lên Git (đã có trong `.gitignore`). Trên repo chỉ có **`google-services.json.example`** để tham khảo cấu trúc.

3. Mở file và kiểm tra: trong `client` → `android_client_info` → `package_name` phải là  
   `com.dongasia.it3237.ride_booking`.

### A4. Bật Authentication (Email/Password)

1. Firebase Console → **Build** → **Authentication** → **Get started**.
2. Tab **Sign-in method** → **Email/Password** → **Enable** → **Save**.

### A5. Tạo Cloud Firestore

1. **Build** → **Firestore Database** → **Create database**.
2. **Edition:** chọn **Standard** (đủ cho đồ án).
3. **Database ID:** thường để **`(default)`**.
4. **Location:** nên chọn gần VN nếu có (ví dụ `asia-southeast1`). **Không đổi được** sau khi tạo.
5. **Security rules** lúc tạo:
   - Có thể chọn **Start in production** rồi sang bước A6 dán rules;  
   - Hoặc **test mode** chỉ để thử nhanh (có thời hạn, kém an toàn).

### A6. Publish Firestore Security Rules

1. Trong repo, mở file **`firestore.rules`** (thư mục gốc `ride_booking`).
2. Firebase Console → Firestore → tab **Rules** → dán toàn bộ nội dung file → **Publish**.

Rules mẫu cho phép user đã đăng nhập chỉ thao tác document **trips** của chính họ (`userId` khớp `request.auth.uid`).

### A7. Liên kết Firebase với Google Cloud (tự động)

Mỗi project Firebase đã gắn một **Google Cloud project** cùng tên. Khi bật Firestore/Auth, GCP đã có sẵn project — **dùng cùng project đó** để bật Maps (phần B) cho đỡ rối.

Kiểm tra: Firebase → **Project settings** (bánh răng) → tab **General** → **Project ID** — trùng với project bạn chọn trên [Google Cloud Console](https://console.cloud.google.com/).

---

## Phần B — Google Maps (Google Cloud Console)

Maps **không** nằm trong Firebase Console; cấu hình tại **Google Cloud Console** của **cùng project** (hoặc project bạn đã liên kết billing).

### B1. Bật billing (thanh toán)

Google Maps Platform thường **yêu cầu** tài khoản thanh toán (billing) trên GCP:

1. [Google Cloud Console](https://console.cloud.google.com/) → chọn **đúng project**.
2. **Billing** → liên kết **billing account** (thẻ/xác minh theo yêu cầu Google).

**Lưu ý:**

- Đây là yêu cầu chống lạm dụng; đồ án nhỏ thường nằm trong **hạn mức miễn phí / credit** của Maps (xem [Pricing](https://developers.google.com/maps/billing-and-pricing/pricing)).
- Nên tạo **Budget + cảnh báo** (Billing → Budgets) để tránh bất ngờ.

### B2. Bật API: Maps SDK for Android (+ Directions tuỳ chọn)

1. **APIs & Services** → **Library** (Thư viện).
2. Tìm **`Maps SDK for Android`**.
3. Vào kết quả → **Enable** (Bật).
4. Bản demo hiện **chỉ chọn điểm đón/đến bằng chạm bản đồ** — không cần Places / Geocoding.
5. Nếu muốn vẽ lộ trình đường bộ (polyline theo đường đi), bật thêm:
   - **Directions API**

**Quan trọng:** Phải **Enable** API này **trước**, khi hạn chế API key (B4) mới thấy tên **Maps SDK for Android** trong danh sách.

### B3. Tạo API key

1. **APIs & Services** → **Credentials**.
2. **Create credentials** → **API key**.
3. **Edit API key** (màn hình chỉnh sửa key vừa tạo).

### B4. Application restrictions (Android)

1. **Application restrictions** → chọn **Android apps**.
2. **Add an item:**
   - **Package name:** `com.dongasia.it3237.ride_booking`
   - **SHA-1 certificate fingerprint:** SHA-1 **debug** (lấy theo **mục A2**: ưu tiên **`keytool`** nếu máy chỉ có JDK 17; hoặc **`.\gradlew.bat signingReport`** trên Windows / **`./gradlew signingReport`** trên macOS khi JVM chạy Gradle đủ mới, ví dụ JDK 21).

*(Khi build release lên CH Play, thêm một dòng nữa với SHA-1 của keystore upload.)*

### B5. API restrictions

1. Chọn **Restrict key**.
2. Trong danh sách, tìm và chọn **`Maps SDK for Android`** (nếu không thấy → quay lại B2 Enable API).

**Không** nên để **Don’t restrict key** lâu dài trên repo công khai.

### B6. Lưu key

1. **Save**.
2. Copy **API key** (dạng `AIza...`) — **không** chia sẻ công khai, **không** paste lên chat nhóm công khai.

### B7. Gắn key vào app Flutter (không commit lên Git)

1. **Copy** file mẫu `android/app/api_keys.xml.example` thành:

   `android/app/src/main/res/values/api_keys.xml`

   (File mẫu **không** đặt trong `res/values/` vì Gradle chỉ chấp nhận tên kết thúc `.xml` trong thư mục đó.)

2. Mở **`api_keys.xml`** (file này đã nằm trong `.gitignore`, không đẩy lên Git) và thay `YOUR_ANDROID_MAPS_API_KEY` bằng API key thật.

3. Kiểm tra `AndroidManifest.xml` đã có (project mẫu đã cấu hình sẵn):

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="@string/google_maps_key" />
   ```

   Chuỗi `google_maps_key` được định nghĩa trong **`api_keys.xml`**, không đặt trong `strings.xml` để tránh lộ key khi push.

---

## Phần C — Kiểm tra sau khi setup

1. Trong thư mục `ride_booking`:

   ```bash
   flutter pub get
   flutter run
   ```

2. **Đăng ký** tài khoản mới → **đăng nhập** → tab **Bản đồ** hiển thị bản đồ (không xám toàn màn hình).
3. **Đặt xe** → Firebase Console → **Firestore** → **Data** → collection **`trips`** có document mới.

### C1. Chạy kèm key Directions (tuỳ chọn — vẽ route đường bộ)

```bash
flutter run --dart-define=DIRECTIONS_API_KEY=YOUR_KEY_HERE
```

Cần bật **Directions API** và dùng key có quyền gọi API đó (xem README).

### Lỗi thường gặp

| Hiện tượng | Hướng xử lý |
|------------|-------------|
| Map trắng / “API key not valid” | Kiểm tra key trong `api_keys.xml`, đã Enable **Maps SDK for Android**, billing đã bật, **Application restrictions** đúng package + SHA-1 debug đang dùng để cài app. |
| `PERMISSION_DENIED` Firestore | Đã **Publish** `firestore.rules`? User đã **đăng nhập**? `userId` trong document có khớp `uid` không? |
| Auth lỗi | **Email/Password** đã bật? `google-services.json` đúng project + đúng package? |

---

## Phần D — Bảo mật & Git

- **Không** commit `google-services.json` và API key lên **GitHub public**. Có thể dùng `google-services.json.example` (ẩn giá trị nhạy cảm) + hướng dẫn nhóm copy file thật vào máy.
- Nếu key đã lộ (chat, screenshot, repo): vào **Credentials** → **Rotate key** / tạo key mới → xóa key cũ → cập nhật `api_keys.xml`.

---

## Tài liệu tham khảo chính thức

- [Firebase — Add Android](https://firebase.google.com/docs/android/setup)
- [FlutterFire](https://firebase.flutter.dev/)
- [Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk/start)
- [API key best practices](https://developers.google.com/maps/api-security-best-practices)

---

*Tài liệu nội bộ nhóm đồ án IT3237 — Đề tài 10.*
