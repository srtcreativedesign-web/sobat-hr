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
        'latitude',
        'longitude',
        'radius_meters',
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

    /**
     * Get effective coordinates (traverse up to parent if null)
     */
    public function getEffectiveCoordinates()
    {
        if ($this->latitude && $this->longitude) {
            return [
                'latitude' => $this->latitude,
                'longitude' => $this->longitude,
                'radius_meters' => $this->radius_meters
            ];
        }

        if ($this->parentOrganization) {
            return $this->parentOrganization->getEffectiveCoordinates();
        }

        // Try to fetch parent if not loaded (lazy load fallback)
        if ($this->parent_id) {
            $parent = Organization::find($this->parent_id);
            if ($parent) {
                return $parent->getEffectiveCoordinates();
            }
        }

        return [
            'latitude' => null,
            'longitude' => null,
            'radius_meters' => null
        ];
    }
}
