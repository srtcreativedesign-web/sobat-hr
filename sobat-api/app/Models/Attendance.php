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
