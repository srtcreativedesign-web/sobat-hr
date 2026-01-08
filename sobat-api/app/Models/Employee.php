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
        'date_of_birth',
        'join_date',
        'position',
        'department',
        'base_salary',
        'status',
        'employment_status',
        'contract_end_date',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
        'join_date' => 'date',
        'contract_end_date' => 'date',
        'base_salary' => 'decimal:2',
    ];

    /**
     * Relationships
     */
    public function user()
    {
        return $this->belongsTo(User::class);
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

    public function approvals()
    {
        return $this->hasMany(Approval::class, 'approver_id');
    }
}
