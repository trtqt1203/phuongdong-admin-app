# Phương Đông Admin

Ứng dụng Android nội bộ bằng Flutter để quản lý lịch hẹn Phương Đông theo thời gian thực qua Firebase.

## Chức năng

- Firebase Email/Password, không có màn hình tự đăng ký.
- Dashboard thời gian thực: tổng đơn, hôm nay, chờ xác nhận, đã xác nhận, biểu đồ 7 ngày và tỷ lệ tư vấn/đo may.
- Danh sách tìm kiếm, lọc, sắp xếp, vuốt để xác nhận/hủy và tạo lịch thủ công.
- Chi tiết khách, gọi điện/SMS/Zalo, báo giá, cọc, ghi chú nội bộ và timeline trạng thái.
- Calendar tháng/tuần/ngày và danh sách khách hàng.
- FCM khi có lịch mới; chạm notification mở đúng chi tiết lịch.
- Owner quản lý nhân viên, giờ làm việc dùng chung và xuất Excel theo khoảng ngày.

## Thiết lập bắt buộc

Làm theo [FIREBASE_SETUP.md](./FIREBASE_SETUP.md). File `google-services.json` và Firebase project thật không nằm trong mã nguồn.

## Kiểm tra mã nguồn

Flutter SDK đã được đặt cục bộ tại `../.tools/flutter`.

```powershell
$env:APPDATA=(Resolve-Path ..\.appdata).Path
$env:LOCALAPPDATA=(Resolve-Path ..\.localappdata).Path
$env:PUB_CACHE=(Resolve-Path ..\.pub-cache).Path
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
```

Để build APK cần cài Android Studio hoặc Android SDK/JDK 17, sau đó:

```powershell
..\.tools\flutter\bin\flutter.bat build apk --release
```

## Cấu trúc chính

- `firestore.rules`: quyền public chỉ tạo booking; admin đã xác thực mới đọc/sửa.
- `functions/index.js`: FCM, tạo nhân viên và vô hiệu hóa nhân viên.
- `functions/migrate_sqlite.js`: chuyển database Antigravity hiện tại sang Firestore.
- `lib/`: toàn bộ Flutter app.
- `website_integration/`: module JavaScript để website gửi booking vào Firestore.

Không đưa service account, `.firebaserc`, `google-services.json` hoặc mật khẩu nhân viên lên Git.
