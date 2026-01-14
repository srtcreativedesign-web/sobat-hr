<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Organization extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'type',
        'parent_id',
        'address',
        'phone',
        'email',
        'line_style',
        'description',
    ];

    /**
     * Relationships
     */
    public function parentOrganization()
    {
        return $this->belongsTo(Organization::class, 'parent_id');
    }

    public function childOrganizations()
    {
        return $this->hasMany(Organization::class, 'parent_id');
    }

    public function employees()
    {
        return $this->hasMany(Employee::class);
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class);
    }
}
