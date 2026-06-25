import { API_URL } from '@/lib/config';
import { Attendance } from './types';

export const getPhotoUrl = (path: string | null) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    const baseUrl = API_URL.replace(/\/api\/?$/, '');
    let cleanPath = path;
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('public/')) cleanPath = cleanPath.substring(7);
    return `${baseUrl}/storage/${cleanPath}`;
};

export const getStatusBadge = (status: string) => {
    switch (status) {
        case 'present': return 'bg-green-100 text-green-800';
        case 'late': return 'bg-yellow-100 text-yellow-800';
        case 'absent': return 'bg-red-100 text-red-800';
        case 'pending': return 'bg-orange-100 text-orange-800 ring-1 ring-orange-500';
        default: return 'bg-gray-100 text-gray-800';
    }
};

export const getReviewBadge = (status: string | null) => {
    switch (status) {
        case 'approved': return 'bg-green-100 text-green-800';
        case 'rejected': return 'bg-red-100 text-red-800';
        case 'pending': return 'bg-yellow-100 text-yellow-800';
        default: return 'bg-gray-100 text-gray-400';
    }
};

export const parseDate = (dt: string) => {
    const d = dt.includes('T') ? new Date(dt) : new Date(dt.replace(' ', 'T'));
    return isNaN(d.getTime()) ? null : d;
};

export const formatDateTime = (dt: string | null) => {
    if (!dt) return '-';
    const d = parseDate(dt);
    if (!d) return dt;
    return d.toLocaleString('id-ID', {
        year: 'numeric', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit',
    });
};

export const getOutletNameDisplay = (att: Attendance) => {
    if (att.outlet?.name) return att.outlet.name;
    const qrData = att.qr_code_data || att.notes;
    if (qrData) {
        try {
            const parsed = JSON.parse(qrData);
            if (parsed.outlet_name) return parsed.outlet_name;
            if (parsed.name) return parsed.name;
        } catch (e) {
            // Not JSON
        }
        // If format is like "Toko-A-LT1-...", extract "Toko-A"
        if (qrData.includes('-LT')) {
            return qrData.split('-LT')[0].replace(/-/g, ' ');
        }
        return qrData;
    }
    return '-';
};

export const formatDate = (att: Attendance) => {
    if (att.date) {
        const d = parseDate(att.date);
        if (!d) return att.date;
        return d.toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' });
    }
    return '-';
};

export const getChipColor = (status: string) => {
    const map: Record<string, "success" | "danger" | "warning" | "default"> = {
        present: "success",
        late: "warning",
        absent: "danger",
        pending: "default"
    };
    return map[status?.toLowerCase()] || "default";
};
