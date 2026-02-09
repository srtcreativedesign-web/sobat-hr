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
        'attendance_type',   // office or field
        'field_notes',       // Notes for field attendance
        'late_duration',     // Minutes late
        'overtime_duration', // Minutes overtime
        'face_verified',     // Boolean: true if face matched
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
}
