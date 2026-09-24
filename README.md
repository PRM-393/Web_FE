# Voucher Platform Web (FE)

Ba web SPA cua nen tang voucher da thuong hieu — **web thuong hieu**, **web cua hang** va
**web quan tri** — dong goi trong **mot** ung dung Vite + React + TypeScript, chia theo route.

## Vi sao mot app duy nhat thay vi 3 goi rieng (monorepo)

Repo `Web_FE` la mot repo duy nhat theo yeu cau du an. Ba nhom nguoi dung (BrandOwner, StoreStaff,
Admin) dung chung mot API, mot he thong xac thuc JWT va phan lon UI component (Button, Card,
Badge, AppShell...). Tach lam ba goi rieng trong workspace se tang chi phi dong bo phu thuoc va
build cho mot doi 4 nguoi trong 7 tuan ma khong mang lai loi ich ro ret. Vi vay repo nay dung
**mot ung dung Vite duy nhat** voi ba khu vuc route rieng biet, moi khu vuc co layout va guard
theo vai tro rieng:

- `/brand/*` — web thuong hieu (BrandOwner)
- `/store/*` — web cua hang / redeem (StoreStaff)
- `/admin/*` — web quan tri (Admin)

Neu ve sau can tach doc lap, cau truc `src/pages/<khu-vuc>` + `src/routes` da san sang de tach
thanh workspace packages ma khong phai viet lai logic.

## Cai dat va chay

```bash
npm install
cp .env.example .env   # chinh VITE_API_BASE_URL tro ve NestJS API
npm run dev             # http://localhost:5173
npm run build            # kiem tra type + build production
```

## Cau truc thu muc

```
src/
  main.tsx, App.tsx        # entry point, khai bao route
  routes/
    RequireRole.tsx         # guard theo vai tro (FR-AUTH-07), chua dang nhap -> /login
  store/
    auth.store.ts            # Zustand store, luu JWT + user trong localStorage
  lib/
    api-client.ts             # axios instance: gan Bearer token, tu refresh khi 401
    auth.api.ts                # goi API dang nhap / OTP / logout
    format.ts                   # formatVND, formatDateTime (Asia/Ho_Chi_Minh)
  components/
    layout/AppShell.tsx          # layout dung chung: sidebar + header + content
    ui/                            # Button, Card, StatusBadge
  pages/
    auth/LoginPage.tsx             # FR-AUTH-06: dang nhap email + mat khau
    brand/                          # FR-BRAND-*, FR-CAMP-*, FR-SETTLE-08, FR-REPORT-01/02
      CampaignListPage, CampaignFormPage, StoreListPage, StaffListPage,
      SettlementListPage, ReportPage
    store/                          # FR-REDEEM-05/06/07/10
      RedeemPage (quet QR camera + nhap OTP), HistoryPage
    admin/                          # FR-REPORT-03/04, FR-BRAND-03, UC-04, FR-SETTLE-01/03/07
      DashboardPage, BrandApprovalPage, CampaignApprovalPage, SettlementAdminPage
    shared/                          # ForbiddenPage, NotFoundPage
  types/                             # AuthUser, Role, Brand, Store, VoucherCampaign, Settlement
```

## Quyet dinh ky thuat

- **State**: Zustand cho phien dang nhap (nhe, khong can boilerplate cua Redux Toolkit cho pham vi
  scaffold nay).
- **API client**: axios voi interceptor gan `Authorization: Bearer <accessToken>` va tu dong goi
  `/auth/refresh` khi gap 401, hang cac request dong thoi lai trong luc refresh (tranh goi refresh
  nhieu lan).
- **Route guard**: `RequireRole` kiem tra vai tro o phia client de dieu huong UX; **backend van la
  nguon xac thuc phan quyen chinh** (NFR-SEC-03) — FE khong tu suy ra quyen tu giao dien an/hien.
- **Man hinh redeem** (`RedeemPage`) dung `navigator.mediaDevices.getUserMedia` de xin quyen
  camera; viec giai ma QR that su la `// TODO` — goi y dung `@zxing/browser` hoac `html5-qrcode`
  o buoc trien khai tiep theo.

## TODO con lai (xem comment trong code)

- Lay dung `brandId` / `storeId` cua nguoi dung dang nhap thay vi placeholder `BRAND_ID` /
  `STORE_ID` (can them endpoint `/brands/me`, `/staff/me` o BE hoac decode tu JWT).
- Tich hop thu vien quet QR that trong `RedeemPage`.
- Form tao chien dich day du (chon nhieu chi nhanh, loai voucher, upload anh).
- Trang quan ly nhan vien cua hang (`StaffListPage`) con la stub.
