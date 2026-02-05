'use client';

import {
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer
} from 'recharts';

interface LatenessData {
    month: string;
    year: number;
    rate: number;
    total: number;
    late: number;
}

interface LatenessChartProps {
    data: LatenessData[];
    loading: boolean;
}

const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
        const data = payload[0].payload;
        return (
            <div className="bg-white p-3 border border-gray-100 shadow-xl rounded-xl">
                <p className="font-bold text-gray-800 mb-1">{`${label} ${data.year}`}</p>
                <p className="text-sm text-[#1C3ECA]">
                    Late Rate: <span className="font-bold">{data.rate}%</span>
                </p>
                <div className="mt-2 pt-2 border-t border-gray-50 text-xs text-gray-500">
                    <p>Total Late: {data.late}</p>
                    <p>Total Attendance: {data.total}</p>
                </div>
            </div>
        );
    }
    return null;
};

export default function LatenessChart({ data, loading }: LatenessChartProps) {
    if (loading) {
        return (
            <div className="h-[300px] w-full flex items-center justify-center bg-gray-50/50 rounded-xl border border-dashed border-gray-200">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1C3ECA]"></div>
            </div>
        );
    }

    if (!data || data.length === 0) {
        return (
            <div className="h-[300px] w-full flex items-center justify-center bg-gray-50/50 rounded-xl border border-dashed border-gray-200">
                <p className="text-gray-400 font-medium">No lateness data available</p>
            </div>
        );
    }

    return (
        <div className="glass-card p-6 bg-white">
            <div className="flex justify-between items-center mb-6">
                <div>
                    <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                        <span className="w-2 h-8 bg-[#1C3ECA] rounded-full"></span>
                        Lateness Trend
                    </h2>
                    <p className="text-sm text-gray-500 mt-1">Percentage of late arrivals per month</p>
                </div>
                <div className="bg-red-50 text-red-600 px-3 py-1 rounded-full text-xs font-bold">
                    Last 6 Months
                </div>
            </div>

            <div className="h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <AreaChart
                        data={data}
                        margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
                    >
                        <defs>
                            <linearGradient id="colorRate" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#1C3ECA" stopOpacity={0.2} />
                                <stop offset="95%" stopColor="#1C3ECA" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                        <XAxis
                            dataKey="month"
                            axisLine={false}
                            tickLine={false}
                            tick={{ fill: '#9ca3af', fontSize: 12 }}
                            dy={10}
                        />
                        <YAxis
                            axisLine={false}
                            tickLine={false}
                            tick={{ fill: '#9ca3af', fontSize: 12 }}
                            tickFormatter={(value) => `${value}%`}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Area
                            type="monotone"
                            dataKey="rate"
                            stroke="#1C3ECA"
                            strokeWidth={3}
                            fillOpacity={1}
                            fill="url(#colorRate)"
                            activeDot={{ r: 6, strokeWidth: 0, fill: '#60A5FA' }}
                        />
                    </AreaChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
