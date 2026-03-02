<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    use HasFactory;

    // --- Role Constants (Single Source of Truth) ---
    const SUPER_ADMIN = 'super_admin';
    const ADMIN = 'admin';
    const ADMIN_CABANG = 'admin_cabang';
    const HRD = 'hrd';
    const HR = 'hr';
    const MANAGER = 'manager';
    const MANAGER_DIVISI = 'manager_divisi';
    const DEPUTY_MANAGER = 'deputy_manager';
    const EMPLOYEE = 'employee';
    const CREW = 'crew';
    const STAFF = 'staff';
    const TEAM_LEADER = 'team_leader';

    protected $fillable = [
        'name',
        'display_name',
        'description',
        'approval_level',
    ];

    /**
     * Relationships
     */
    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function employees()
    {
        return $this->hasMany(Employee::class);
    }
}
