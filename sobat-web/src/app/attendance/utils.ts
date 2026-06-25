import { API_URL } from '@/lib/config';

export const formatDate = (dateString: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
        year: 'numeric'
    });
};

export const getPhotoUrl = (path: string | null) => {
    if (!path) return null;

    // If path is already a full URL, return it
    if (path.startsWith('http')) return path;

    // Ensure we have a valid base URL for storage
    // API_URL usually ends with /api. We need the base URL (without /api)
    const baseUrl = API_URL.replace(/\/api\/?$/, '');

    // Remove leading slash or 'public/' from path if present (Laravel storage standard)
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
        case 'leave': return 'bg-blue-100 text-blue-800';
        case 'sick': return 'bg-orange-100 text-orange-800';
        case 'pending': return 'bg-orange-100 text-orange-800 ring-1 ring-orange-500';
        default: return 'bg-gray-100 text-gray-800';
    }
};

export const getStatusColor = (status: string) => {
    const map: Record<string, "success" | "danger" | "warning" | "default" | "primary"> = {
        present: "success",
        late: "warning",
        absent: "danger",
        leave: "primary",
        sick: "primary",
        pending: "default"
    };
    return map[status] || "default";
};

export const getStatusText = (status: string) => {
    const map: Record<string, string> = {
        present: 'Hadir',
        late: 'Terlambat',
        absent: 'Alpa',
        leave: 'Izin',
        sick: 'Sakit',
        pending: 'Pending'
    };
    return map[status] || status;
};
