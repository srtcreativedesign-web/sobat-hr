'use client';

import DashboardLayout from '@/components/DashboardLayout';
import QrManagement from '@/components/features/QrManagement';

export default function QrGeneratorPage() {
  return (
    <DashboardLayout>
      <div className="p-8">
        <QrManagement />
      </div>
    </DashboardLayout>
  );
}
