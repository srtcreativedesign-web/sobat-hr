import React from 'react';
import { AreaChart, Area, ResponsiveContainer } from 'recharts';

interface MetricCardProps {
  title: string;
  value: string | number;
  trend?: number; // e.g. 2.4 for +2.4%
  trendLabel?: string; // e.g. "vs last month"
  data: any[]; // Data for sparkline
  dataKey: string; // Key for the area chart
  color?: string; // Hex color for the chart line/fill
}

export default function MetricCard({ 
  title, 
  value, 
  trend, 
  trendLabel, 
  data, 
  dataKey, 
  color = "#8b5cf6" 
}: MetricCardProps) {
  const isPositive = trend !== undefined && trend > 0;
  
  return (
    <div className="rounded-2xl border border-gray-200 bg-gray-50/70 p-2 overflow-hidden flex flex-col h-full">
      {/* Header / Title */}
      <div className="px-4 py-3">
        <h3 className="text-[15px] font-bold text-gray-800">{title}</h3>
      </div>
      
      {/* Inner White Card */}
      <div className="bg-white rounded-[14px] border border-gray-100 shadow-sm flex-1 flex flex-col relative overflow-hidden">
        <div className="p-5 pb-0 flex justify-between items-start z-10">
          <div>
            <div className="flex items-baseline gap-3">
              <h4 className="text-4xl font-bold text-gray-900 tracking-tight">{value}</h4>
              {trend !== undefined && (
                <div className="flex items-center gap-1.5">
                  <span className={`flex items-center text-sm font-bold ${isPositive ? 'text-green-500' : 'text-red-500'}`}>
                    {isPositive ? (
                      <svg className="w-4 h-4 mr-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>
                    ) : (
                      <svg className="w-4 h-4 mr-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M13 17h8m0 0v-8m0 8l-8-8-4 4-6-6" /></svg>
                    )}
                    {Math.abs(trend)}%
                  </span>
                  {trendLabel && (
                    <span className="text-[13px] font-medium text-gray-500">{trendLabel}</span>
                  )}
                </div>
              )}
            </div>
          </div>
          

        </div>
        
        {/* Sparkline Chart */}
        <div className="h-20 w-full mt-2 translate-y-1">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 5, right: 0, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id={`color-\${dataKey}`} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={color} stopOpacity={0.15}/>
                  <stop offset="95%" stopColor={color} stopOpacity={0}/>
                </linearGradient>
              </defs>
              <Area 
                type="monotone" 
                dataKey={dataKey} 
                stroke={color} 
                strokeWidth={2}
                fillOpacity={1} 
                fill={`url(#color-\${dataKey})`} 
                isAnimationActive={true}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
