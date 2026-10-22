# Báo cáo hoàn thiện F02, F03, F04, F05 và F14

Ngày kiểm tra: 21/10/2026 (UTC+7).

## Phạm vi đã hoàn thiện

- **F02 – Xác thực và phân quyền:** OTP email, đếm ngược gửi lại, `deviceId` bền vững, refresh token xoay vòng, chống refresh đồng thời, đăng xuất thu hồi phiên, kích hoạt tài khoản, quên/đặt lại mật khẩu và chặn route theo vai trò.
- **F03 – Danh mục và tìm kiếm:** quản trị danh mục trên web; Mobile tìm theo tên voucher/thương hiệu, lọc giá, mức giảm, bán kính, sắp xếp, phân trang 20 mục và xử lý khi từ chối vị trí.
- **F04 – Gần tôi và bản đồ:** lấy vị trí, tính khoảng cách, danh sách cửa hàng gần, bản đồ OpenStreetMap và mở chỉ đường.
- **F05 – Chi tiết voucher:** giá, giảm giá, điều kiện, hạn, chi nhánh, tồn kho, chính sách hoàn, đánh giá và trạng thái mua.
- **F14 – Báo cáo và dashboard:** báo cáo thương hiệu, đối soát và dashboard quản trị theo dữ liệu API.

## Kết quả tự động

| Thành phần | Kiểm tra | Kết quả |
|---|---|---:|
| Web_BE | Jest unit | 38/38 đạt |
| Web_BE | Jest e2e | 26/26 đạt |
| Web_FE | Flutter widget/unit | 63/63 đạt |
| Mobile_App | Flutter widget/unit | 26/26 đạt |
| Toàn hệ thống | Tổng test tự động | **153/153 đạt** |
| Luồng thật | PostgreSQL + SMTP + API | **15/15 đạt** |

Các build đã thành công: BE production build, Flutter Web release và Android debug APK. `flutter analyze` đạt trên cả Web_FE và Mobile_App.

## Kiểm tra tích hợp thật

Kịch bản `live-smoke.json` chạy với PostgreSQL cục bộ và SMTP Gmail đã cấu hình. Kết quả xác nhận:

- gửi và xác minh OTP thành công; OTP không thể dùng lại;
- hai yêu cầu refresh đồng thời chỉ có một yêu cầu thành công;
- đăng xuất thu hồi phiên;
- link đặt lại mật khẩu dùng một lần, thu hồi phiên cũ và mật khẩu mới đăng nhập được;
- 5/5 yêu cầu tìm kiếm công khai thành công.

Thời gian 5 lần gọi API tìm kiếm cục bộ: **15, 6, 6, 6, 5 ms**; trung bình **7,6 ms**, thấp hơn mục tiêu 3 giây. Số liệu này là thời gian API trong môi trường cục bộ, không gồm độ trễ mạng Render.

## Bằng chứng giao diện

- `web-login.png`: đăng nhập Flutter Web trên màn rộng.
- `web-admin-categories.png`: đăng nhập admin thành công và tải danh mục từ API.
- `mobile-home.png`: APK chạy trên Android emulator và tải Home từ API.

## Lệnh kiểm tra lại

```powershell
# Web_FE
flutter analyze
flutter test
flutter build web --release

# Mobile_App
flutter analyze
flutter test
flutter build apk --debug

# Web_BE
npm run build
npm test -- --runInBand
npm run test:e2e -- --runInBand
```

Email thử nghiệm có tiền tố `[KIỂM THỬ VOUCHER]`. Máy chủ SMTP đã chấp nhận hai thư; việc thư xuất hiện trong hộp thư đến phụ thuộc Gmail và người dùng có thể kiểm tra trực tiếp.
