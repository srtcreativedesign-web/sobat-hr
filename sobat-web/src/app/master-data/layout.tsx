'use client';

import DashboardLayout from '@/components/DashboardLayout';

export default function MasterDataLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <DashboardLayout>
            {children}
        </DashboardLayout>
    );
}
