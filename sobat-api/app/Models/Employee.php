<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'organization_id',
        'role_id',
        'shift_id',
        'employee_code',
        'full_name',
        'email',
        'phone',
        'address',
        'birth_date',
        'join_date',
        'position',
        'department',
        'level',
        'basic_salary',
        'status',
        'employment_status',
        'contract_end_date',
        'job_level',
        'track',
        'join_date_edit_count',
        // New fields
        'place_of_birth',
        'ktp_address',
        'current_address',
        'gender',
        'religion',
        'marital_status',
        'ptkp_status',
        'nik',
        'npwp',
        'bank_account_number',
        'bank_account_name',
        'father_name',
        'mother_name',
        'spouse_name',
        'family_contact_number',
        'education',
        'supervisor_name',
        'supervisor_position',
        'supervisor_id', // Added
        'photo_path',
    ];

    protected $casts = [
        'birth_date' => 'date',
        'join_date' => 'date',
        'contract_end_date' => 'date',
        'basic_salary' => 'decimal:2',
        'education' => 'array',
    ];

    /**
     * Relationships
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    
    public function supervisor()
    {
        return $this->belongsTo(Employee::class, 'supervisor_id');
    }

    public function organization()
    {
        return $this->belongsTo(Organization::class);
    }

    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function payrolls()
    {
        return $this->hasMany(Payroll::class);
    }

    public function requests()
    {
        return $this->hasMany(RequestModel::class);
    }

    public function jobPosition()
    {
        return $this->belongsTo(JobPosition::class, 'position', 'name');
    }

    public function approvals()
    {
        return $this->hasMany(Approval::class, 'approver_id');
    }
}
