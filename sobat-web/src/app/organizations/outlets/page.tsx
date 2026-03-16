'use client';

import DashboardLayout from '@/components/DashboardLayout';
import OutletManagement from '@/components/features/OutletManagement';

export default function OutletManagementPage() {
    return (
        <DashboardLayout>
            <div className="p-8">
                <OutletManagement />
            </div>
        </DashboardLayout>
    );
}
