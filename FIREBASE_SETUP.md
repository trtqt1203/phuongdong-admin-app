# Thiết lập Firebase cho Phương Đông Admin

Các bước trong Firebase Console cần chủ dự án thực hiện vì chúng tạo tài nguyên cloud, tài khoản và thông tin thanh toán thuộc quyền sở hữu của bạn.

## 1. Tạo Firebase project

1. Mở Firebase Console và tạo project, ví dụ `phuong-dong-tailor`.
2. Chọn khu vực Firestore gần Việt Nam. Khu vực database không thể đổi sau khi tạo.
3. Nâng project lên gói Blaze trước khi deploy Cloud Functions. Đặt cảnh báo ngân sách trong Google Cloud Billing.

## 2. Tạo Firestore

1. Vào **Build → Firestore Database → Create database**.
2. Chọn **Production mode**.
3. Sao chép `.firebaserc.example` thành `.firebaserc` và thay `YOUR_FIREBASE_PROJECT_ID`.
4. Cài Firebase CLI rồi đăng nhập:

```powershell
npm.cmd install -g firebase-tools
firebase login
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes
```

Rules trong [firestore.rules](./firestore.rules) bảo đảm:

- Website chưa đăng nhập chỉ được tạo booking ở trạng thái `pending`.
- Website không thể đọc, sửa, xóa booking hoặc ghi báo giá/adminNote.
- Chỉ tài khoản có hồ sơ `admins/{uid}` hợp lệ mới quản lý booking.
- Chỉ `owner` được quản lý tài khoản nhân viên.

## 3. Bật Authentication và tạo owner đầu tiên

1. Vào **Build → Authentication → Sign-in method** và bật **Email/Password**.
2. Trong tab **Users**, chọn **Add user** và tạo tài khoản chủ shop.
3. Sao chép UID của tài khoản.
4. Trong Firestore tạo document `admins/{UID}`:

```text
email: "email-cua-chu-shop@example.com"
role: "owner"
disabled: false
createdAt: Timestamp hiện tại
```

Ứng dụng không có nút đăng ký. Sau khi owner đăng nhập, mục **Cài đặt → Nhân viên** gọi Cloud Functions để tạo các tài khoản khác mà không làm phiên owner bị thay đổi.

## 4. Kết nối Android

1. Trong **Project settings → Your apps**, thêm Android app.
2. Android package name phải đúng: `vn.phuongdong.phuong_dong_admin`.
3. Tải `google-services.json` và đặt tại `android/app/google-services.json`.
4. Không dùng file `.example` như credential thật.
5. Cloud Messaging được bật cùng Firebase project. Android 13+ sẽ hỏi quyền thông báo khi admin đăng nhập.

## 5. Deploy Cloud Functions

```powershell
cd functions
npm.cmd install
npm.cmd audit
firebase deploy --only functions
```

Functions được đặt tại `asia-southeast1`:

- `onBookingCreated`: gửi FCM đến các token đang bật.
- `createAdminUser`: chỉ owner được tạo admin/staff.
- `disableAdminUser`: chỉ owner được vô hiệu hóa nhân viên và xóa FCM token của người đó.

Payload notification chứa `bookingId` và `screen=detail`. App xử lý foreground, background và trạng thái đã đóng.

## 6. Cấu hình giờ làm việc

Sau khi owner đăng nhập, vào **Cài đặt → Giờ làm việc** và lưu. App tạo `settings/public` gồm:

```text
openTime: "09:00"
closeTime: "18:00"
workDays: [1, 2, 3, 4, 5, 6]
holidays: ["2026-09-02"]
```

Document này được website đọc công khai để khóa ngày nghỉ; chỉ admin được sửa.

## 7. Kết nối website Antigravity

Website hiện tại đang dùng SQLite, không còn dùng `window.storage`. Chỉ chuyển khi Firebase đã deploy và backup SQLite đã được tạo.

1. Trong Firebase Console thêm một **Web app**.
2. Chép `website_integration/.env.local.example` vào `.env.local` của Antigravity và điền cấu hình Web app.
3. Trong Antigravity chạy `npm.cmd install firebase`.
4. Chép `website_integration/firebase-bookings.js` vào source website.
5. Trong form đặt lịch, thay hàm gọi API SQLite bằng:

```javascript
const order = await createFirebaseBooking({
  type: 'tuvan',
  name: formData.fullName,
  phone: formData.phoneNumber,
  email: formData.email,
  product: suitConfig.fabric,
  budget: '',
  note: formData.notes,
  date: formData.preferredDate,
  time: formData.preferredTime,
  payMethod: '',
});
```

Không cho website đọc thẳng collection `bookings`. Trang tra cứu của khách cần một API/callable riêng trả về dữ liệu đã rút gọn và kiểm tra mã đơn + số điện thoại; không nới Firestore Rules để cho phép public READ.

## 8. Chuyển dữ liệu SQLite hiện tại

1. Tạo backup database Antigravity.
2. Tạo service account chỉ dùng cho lần migrate, tải JSON và đặt ngoài repository.
3. Thiết lập biến `GOOGLE_APPLICATION_CREDENTIALS` rồi chạy:

```powershell
cd functions
$env:GOOGLE_APPLICATION_CREDENTIALS='C:\duong-dan-an-toan\service-account.json'
node migrate_sqlite.js C:\Users\Administrator\Documents\antigravity\data\phuong-dong.sqlite
```

4. Kiểm tra số lượng và một vài booking trong Firestore.
5. Xóa service-account JSON khỏi máy nếu không còn cần và thu hồi key trong Google Cloud Console.

## 9. Build và cài Android

Máy hiện chưa có Android SDK/JDK. Cài Android Studio, Android SDK Platform và JDK 17; sau đó chạy:

```powershell
flutter doctor
flutter build apk --release
```

APK nằm tại `build/app/outputs/flutter-apk/app-release.apk`.

Trước khi phát hành qua Play Store, thay cấu hình ký debug mặc định trong `android/app/build.gradle.kts` bằng keystore release được lưu bên ngoài repository.

## 10. Trước khi dùng thật

- Bật Firebase App Check cho Web và Android.
- Tạo tối đa số tài khoản nhân viên cần thiết, dùng mật khẩu riêng và bật MFA nếu chính sách Firebase project hỗ trợ.
- Không lưu ảnh khách vào Firestore; dùng Cloud Storage với rules riêng và chính sách xóa.
- Bật budget alert, Cloud Logging và kiểm tra khôi phục dữ liệu định kỳ.
- Thử notification trên thiết bị Android thật ở cả foreground, background và terminated.
