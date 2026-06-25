export interface Attendance {
    id: number;
    employee_id: number;
    employee?: {
        full_name: string;
        employee_code: string;
    };
    date: string;
    check_in: string | null;
    check_out: string | null;
    status: 'present' | 'late' | 'absent' | 'leave' | 'sick' | 'pending';
    notes: string | null;
    photo_path: string | null;
    checkout_photo_path: string | null;
    work_hours: number | null;
    location_address: string | null;
    attendance_type?: 'office' | 'field';
    field_notes?: 'string' | null;
    is_offline?: boolean;
    validation_method?: 'qr_code' | 'gps';
    latitude?: number | null;
    longitude?: number | null;
    device_id?: string;
    device_timestamp?: string;
    time_discrepancy_seconds?: number;
}
