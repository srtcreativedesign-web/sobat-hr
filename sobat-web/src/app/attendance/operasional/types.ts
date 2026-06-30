export interface Attendance {
    id: number;
    employee_id: number;
    employee: {
        full_name: string;
        employee_code: string;
        division?: { id: number; name: string };
    } | null;
    outlet: { id: number; name: string } | null;
    date: string;
    check_in: string | null;
    check_out: string | null;
    status: string;
    review_status: 'pending' | 'approved' | 'rejected' | null;
    review_notes: string | null;
    validation_method: 'qr_code' | 'gps' | 'online_gps' | null;
    track_type: string;
    qr_code_data: string | null;
    floor_number: number | null;
    photo_path: string | null;
    checkout_photo_path: string | null;
    device_id: string | null;
    device_timestamp: string | null;
    time_discrepancy_seconds: number | null;
    is_offline: boolean;
    shift_start_time?: string | null;
    shift_end_time?: string | null;
    notes?: string | null;
    latitude?: number | string | null;
    longitude?: number | string | null;
    location_address?: string | null;
}
