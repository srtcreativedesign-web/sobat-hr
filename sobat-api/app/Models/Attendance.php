<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'date',
        'check_in',
        'check_out',
        'work_hours',
        'status',
        'notes',
        'latitude',
        'longitude',
        'photo_path',
        'checkout_photo_path',
        'location_address',
        'attendance_type',
        'field_notes',
        'late_duration',
        'overtime_duration',
        'face_verified',
        'face_verification_status',

        // Offline & Advanced Validation Fields
        'track_type',
        'validation_method',
        'is_offline',
        'qr_code_data',
        'outlet_id',
        'location_id',
        'location_name',
        'floor_number',
        'device_timestamp',
        'server_timestamp',
        'time_discrepancy_seconds',
        'device_id',
        'device_uptime_seconds',
        'review_status',
        'review_notes',
    ];

    protected $casts = [
        'date' => 'date',
        'work_hours' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function outlet()
    {
        return $this->belongsTo(Organization::class, 'outlet_id');
    }
}
