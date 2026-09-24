import { Navigate, Route, Routes } from 'react-router-dom';
import { LoginPage } from '@/pages/auth/LoginPage';
import { ForbiddenPage } from '@/pages/shared/ForbiddenPage';
import { NotFoundPage } from '@/pages/shared/NotFoundPage';
import { RequireRole } from '@/routes/RequireRole';

import { BrandLayout } from '@/pages/brand/BrandLayout';
import { CampaignListPage } from '@/pages/brand/CampaignListPage';
import { CampaignFormPage } from '@/pages/brand/CampaignFormPage';
import { StoreListPage } from '@/pages/brand/StoreListPage';
import { StaffListPage } from '@/pages/brand/StaffListPage';
import { SettlementListPage } from '@/pages/brand/SettlementListPage';
import { ReportPage } from '@/pages/brand/ReportPage';

import { StoreLayout } from '@/pages/store/StoreLayout';
import { RedeemPage } from '@/pages/store/RedeemPage';
import { HistoryPage } from '@/pages/store/HistoryPage';

import { AdminLayout } from '@/pages/admin/AdminLayout';
import { DashboardPage } from '@/pages/admin/DashboardPage';
import { BrandApprovalPage } from '@/pages/admin/BrandApprovalPage';
import { CampaignApprovalPage } from '@/pages/admin/CampaignApprovalPage';
import { SettlementAdminPage } from '@/pages/admin/SettlementAdminPage';

// Cau truc route theo 3 khu vuc /brand, /store, /admin trong cung mot ung dung Vite
// (xem quyet dinh ky thuat trong README.md).
export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/forbidden" element={<ForbiddenPage />} />

      <Route
        path="/brand"
        element={
          <RequireRole roles={['BRAND_OWNER']}>
            <BrandLayout />
          </RequireRole>
        }
      >
        <Route index element={<Navigate to="campaigns" replace />} />
        <Route path="campaigns" element={<CampaignListPage />} />
        <Route path="campaigns/new" element={<CampaignFormPage />} />
        <Route path="stores" element={<StoreListPage />} />
        <Route path="staff" element={<StaffListPage />} />
        <Route path="settlements" element={<SettlementListPage />} />
        <Route path="reports" element={<ReportPage />} />
      </Route>

      <Route
        path="/store"
        element={
          <RequireRole roles={['STORE_STAFF']}>
            <StoreLayout />
          </RequireRole>
        }
      >
        <Route index element={<Navigate to="redeem" replace />} />
        <Route path="redeem" element={<RedeemPage />} />
        <Route path="history" element={<HistoryPage />} />
      </Route>

      <Route
        path="/admin"
        element={
          <RequireRole roles={['ADMIN']}>
            <AdminLayout />
          </RequireRole>
        }
      >
        <Route index element={<Navigate to="dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="approvals/brands" element={<BrandApprovalPage />} />
        <Route path="approvals/campaigns" element={<CampaignApprovalPage />} />
        <Route path="settlements" element={<SettlementAdminPage />} />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
