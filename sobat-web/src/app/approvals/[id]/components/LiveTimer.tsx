import React, { useEffect, useState } from 'react';

export default function LiveTimer({ startTime, date }: { startTime: string, date: string }) {
    const [duration, setDuration] = useState('00:00:00');

    useEffect(() => {
        const updateTimer = () => {
            const now = new Date();
            const dateOnly = date.split('T')[0];
            const startStr = `${dateOnly}T${startTime}`;
            const start = new Date(startStr);
            if (isNaN(start.getTime())) return;
            
            const diffInSeconds = Math.floor((now.getTime() - start.getTime()) / 1000);
            if (diffInSeconds < 0) return;

            const h = Math.floor(diffInSeconds / 3600);
            const m = Math.floor((diffInSeconds % 3600) / 60);
            const s = diffInSeconds % 60;
            
            setDuration(
                `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
            );
        };
        
        updateTimer(); // Initial call
        const interval = setInterval(updateTimer, 1000);
        return () => clearInterval(interval);
    }, [startTime, date]);

    return <span className="font-mono text-[#1C3ECA] font-bold">{duration}</span>;
}
