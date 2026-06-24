import React from 'react';
import { Card, CardHeader, CardBody, User, Chip, Skeleton } from '@nextui-org/react';

interface LeaderboardItem {
  employee_id: number;
  total: number;
  employee: {
    user: {
      name: string;
    };
  };
}

interface TopOnTimeLeaderboardProps {
  data: LeaderboardItem[] | undefined;
  loading: boolean;
}

export default function TopOnTimeLeaderboard({ data, loading }: TopOnTimeLeaderboardProps) {
  return (
    <Card className="border-none bg-white/50 shadow-sm glass-card border-success-100/50">
      <CardHeader className="flex gap-2 justify-between px-6 pt-6 pb-2">
        <div className="flex items-center gap-2">
          <span className="w-2 h-6 bg-success rounded-full"></span>
          <h3 className="text-lg font-bold text-gray-800">Top 5 Paling Rajin</h3>
        </div>
        <Chip size="sm" color="success" variant="flat" className="font-semibold">
          Bulan Ini
        </Chip>
      </CardHeader>
      <CardBody className="px-6 pb-6 pt-2">
        {loading ? (
          <div className="space-y-4">
            <Skeleton className="h-12 w-full rounded-lg" />
            <Skeleton className="h-12 w-full rounded-lg" />
            <Skeleton className="h-12 w-full rounded-lg" />
          </div>
        ) : !data || data.length === 0 ? (
          <div className="py-6 text-center border border-dashed border-gray-200 rounded-lg">
            <p className="text-sm text-gray-400">Belum ada data kehadiran.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {data.map((item, idx) => (
              <div 
                key={`early-${item.employee_id}`} 
                className="flex justify-between items-center p-3 bg-success-50/50 rounded-xl border border-success-100 hover:bg-success-50 transition-colors"
              >
                <div className="flex items-center gap-4">
                  <span className="text-lg font-bold text-success-400 w-4 text-center">
                    {idx + 1}
                  </span>
                  <User
                    avatarProps={{
                      radius: "md",
                      name: item.employee?.user?.name?.charAt(0) || '?',
                      className: "bg-success-100 text-success-600 font-bold"
                    }}
                    description={
                      <span className="text-xs text-success-600 font-medium">
                        {item.total} kali tepat waktu
                      </span>
                    }
                    name={
                      <span className="text-sm font-semibold text-gray-800">
                        {item.employee?.user?.name || 'Unknown'}
                      </span>
                    }
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </CardBody>
    </Card>
  );
}
