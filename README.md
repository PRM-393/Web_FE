# Web_FE – Web thương hiệu, cửa hàng và quản trị (Flutter Web)

Ba web của Nền tảng bán và sử dụng voucher đa thương hiệu (môn PRM393), gộp trong **một app Flutter Web**.
Mỗi vai trò có khu vực riêng: `/brand`, `/store` và `/admin`.
Tài liệu đặc tả: `Document/SRS-Voucher-Platform.docx` (v1.1). Kiến trúc giống repo `Mobile_App` để cả nhóm dùng chung một cách làm.

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ / framework | Dart 3, Flutter 3 (Material 3), build cho Web |
| Quản lý trạng thái | `provider` (ChangeNotifier, MultiProvider) |
| Điều hướng | Named routes + `onGenerateRoute`, chặn route theo vai trò |
| Gọi API | `http` qua một `ApiClient` dùng chung, tự làm mới token khi 401 |
| Lưu phiên | `flutter_secure_storage` (trên web lưu localStorage, mã hóa bằng WebCrypto) |
| Quét QR | `mobile_scanner` (camera của trình duyệt) |
| Định dạng / ngôn ngữ | `intl`, `flutter_localizations` (tiếng Việt, tiền VND, giờ UTC+7) |

## Chạy dự án

Yêu cầu: Flutter SDK 3.47.x và Chrome. **Không cần chạy BE hay cài CSDL**: app mặc định gọi BE đã deploy trên Render
(`lib/config/env.dart`).

```bash
flutter pub get
flutter run -d chrome --web-port 5173
```

- Lần gọi đầu có thể mất 30–60 giây vì Render gói free đang "ngủ"; các lần sau nhanh bình thường.
- Tài khoản mẫu (mật khẩu `Voucher@123`): `owner@highlands.local`, `staff@highlands.local`, `admin@voucher.local`.
- Chạy với BE trên máy mình: thêm `--dart-define=API_BASE_URL=http://localhost:3000/api`. Giữ cổng `5173` cho khớp `CORS_ORIGIN`.
- Camera chỉ hoạt động trên `localhost` hoặc HTTPS. Khi thử trên điện thoại qua mạng LAN, hãy dùng ô nhập OTP.
- Không hard-code địa chỉ máy chủ trong mã nguồn (NFR-MNT-02); đổi BE production thì sửa `Env.defaultBackend`.

Kiểm tra trước khi tạo PR:

```bash
flutter analyze
flutter test
```

## Triển khai lên Vercel

Cấu hình nằm sẵn trong repo, không phải chỉnh gì thêm:

- `vercel.json`: Vercel chạy `scripts/vercel-install.sh` (tải Flutter 3.47.3, cùng bản với CI), rồi `scripts/vercel-build.sh`
  (`flutter build web --release`), phục vụ thư mục `build/web`.
- Lần đầu (trưởng nhóm làm một lần): vercel.com → Add New → Project → import repo **Web_FE**. Framework Preset để **Other**,
  giữ nguyên các lệnh, bấm Deploy. Mỗi lần push lên `main` Vercel tự deploy lại; mỗi PR có link preview riêng.
- Không bắt buộc: biến `API_BASE_URL` trong Vercel → Settings → Environment Variables để trỏ sang BE khác. Bỏ trống thì
  dùng BE Render mặc định.
- BE đã cho phép CORS từ mọi tên miền `*.vercel.app`, nên link production và preview đều gọi được API.
- Build lần đầu mất khoảng 5–7 phút vì phải tải Flutter.

## Vai trò và màn hình

Đăng nhập bằng email và mật khẩu (FR-AUTH-06). Sau khi đăng nhập, mỗi vai trò vào đúng trang chủ của mình.
Tài khoản khách hàng bị từ chối và được hướng dẫn dùng app di động.

| Vai trò | Route | Màn hình | Yêu cầu SRS |
|---|---|---|---|
| Chủ thương hiệu | `/brand/campaigns`, `/brand/campaign-form` | Danh sách, tạo / sửa nháp, gửi duyệt, tạm dừng / bán lại | FR-CAMP-01..09, BR-17, BR-26, DC-10 |
| | `/brand/stores` | Chi nhánh: thêm (có tọa độ), vô hiệu hóa | FR-BRAND-04, DC-05 |
| | `/brand/staff` | Nhân viên: gán vào chi nhánh, vô hiệu hóa | FR-BRAND-05/06, BR-19 |
| | `/brand/reviews` | Đánh giá và phản hồi | FR-ENGAGE-04 |
| | `/brand/reports`, `/brand/settlements` | Báo cáo, phiếu đối soát | FR-REPORT-01/02, FR-SETTLE-08 |
| | `/brand/profile` | Đăng ký hồ sơ, trạng thái duyệt | FR-BRAND-01..03 |
| Nhân viên cửa hàng | `/store/select` | Chọn chi nhánh làm việc | FR-AUTH-12, BR-07 |
| | `/store/redeem` | Quét QR / nhập OTP, giá trị hóa đơn, kết quả xanh / đỏ | FR-REDEEM-05..08, NFR-USA-03 |
| | `/store/history` | Lịch sử xác nhận trong ngày | FR-REDEEM-10 |
| Quản trị viên | `/admin/dashboard` | Số liệu toàn sàn | FR-REPORT-03 |
| | `/admin/brands`, `/admin/campaigns` | Duyệt / từ chối kèm lý do | FR-BRAND-03, UC-04 |
| | `/admin/settlements` | Tỷ lệ hoa hồng, chốt đối soát tháng trước, đánh dấu đã chi trả | UC-05, FR-SETTLE-01/07 |
| | `/admin/refunds` | Xác nhận hoàn tiền thủ công | FR-REFUND-06 |

Màn rộng từ 900px dùng menu cố định bên trái. Màn hẹp (điện thoại của nhân viên) dùng Drawer.

## Cấu trúc thư mục

```
lib/
  main.dart              # khởi tạo service, khôi phục phiên, MultiProvider; buildApp() dùng lại trong test
  routes.dart            # AppRoutes: tên route, homeOf(role), chặn theo vai trò, onGenerateRoute
  config/env.dart        # API_BASE_URL đọc từ --dart-define
  theme/app_theme.dart   # màu, khoảng cách, ThemeData (giống Mobile_App)
  models/                # lớp dữ liệu + fromJson: brand, campaign, finance, redeem, auth_user
  services/              # ApiClient, TokenStorage, AuthService, portal_services (Brand/Campaign/Redeem/Admin)
  providers/             # AuthProvider, BrandProvider (thương hiệu + chi nhánh), StoreSessionProvider (ca làm việc)
  screens/auth|brand|store|admin|shared/
  widgets/               # PortalShell (khung + menu), BrandGate, StatusChip, AsyncBody, QrScannerView...
  utils/                 # format (VND, giờ VN), validators (form + ràng buộc chiến dịch)
test/
  helpers/fake_backend.dart  # giả lập Web_BE bằng MockClient, MemoryTokenStorage
  unit/                      # model, validators, providers
  widget/                    # đăng nhập, chặn route, portal thương hiệu, xác nhận sử dụng (cả màn 375px)
```

Quy ước bắt buộc (giống Mobile_App):

1. **Widget không gọi `http` trực tiếp.** Luồng luôn là `Screen → Provider/Service → ApiClient`.
2. Trạng thái dùng chung giữa nhiều màn đặt trong Provider: đăng nhập, thương hiệu đang quản lý, chi nhánh đang làm. Danh sách chỉ dùng trong một màn thì tải bằng `FutureBuilder` (widget `AsyncBody`).
3. Thêm màn mới:
   - Tạo file trong `screens/<vai trò>/` và bọc nội dung bằng `PortalShell(currentRoute: ...)`.
   - Khai báo tên route trong `AppRoutes`. Tiền tố `/brand/`, `/store/` hoặc `/admin/` tự quyết định vai trò được vào.
   - Thêm mục menu trong `widgets/portal_shell.dart`.
4. Kiểm tra form bằng `validators.dart` và hiển thị lỗi tiếng Việt. Máy chủ vẫn kiểm tra lại toàn bộ (NFR-SEC-03).
5. Ngày nhập trên form tính theo giờ Việt Nam rồi đổi sang UTC trước khi gửi (`vnStartOfDayUtc`, `vnEndOfDayUtc`, BR-25).
6. Mỗi màn hoặc luồng mới cần thêm widget test dùng `FakeBackend`. Comment ghi mã yêu cầu SRS để truy vết.

## API máy chủ đang dùng

`/auth/login|refresh|logout`, `/brands`, `/brands/me`, `/brands/:id/stores|staff|reviews|report|settlements`,
`/brands/stores/:id/deactivate`, `/brands/staff`, `/brands/staff/:id/deactivate`, `/reviews/:id/reply`,
`/campaigns/brand/:brandId`, `/campaigns/:id`, `/campaigns/:id/submit|pause|resume|approve|reject`,
`/redeem`, `/redeem/my-stores`, `/redeem/history/today`, `/admin/dashboard`, `/admin/pending/brands|campaigns`,
`/admin/commission-rate`, `/admin/settlements`, `/admin/settlements/run`, `/admin/settlements/:id/mark-paid`,
`/refunds/manual-pending`, `/refunds/:id/confirm-manual`. Xem Swagger của BE tại `http://localhost:3000/docs`.

## Phân công

Theo `Document/Phan-cong-cong-viec-Voucher.xlsx` (sheet "Tính năng", mã F01–F18).
Tạo nhánh `feature/Fxx-ten-ngan` từ `main`, mở PR và cần ít nhất một người review.
