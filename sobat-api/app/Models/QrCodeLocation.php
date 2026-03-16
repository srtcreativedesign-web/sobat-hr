<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QrCodeLocation extends Model
{
    use HasFactory;

    protected $fillable = [
        'organization_id',
        'qr_code',
        'floor_number',
        'location_name',
        'is_active',
        'installed_at',
        'notes',
    ];

    protected $casts = [
        'floor_number' => 'integer',
        'is_active' => 'boolean',
        'installed_at' => 'date',
    ];

    /**
     * Get the organization that owns this QR code location
     */
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Scope to get only active QR codes
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to get QR codes for a specific organization
     */
    public function scopeForOrganization($query, int $organizationId)
    {
        return $query->where('organization_id', $organizationId);
    }

    /**
     * Scope to get QR codes for a specific floor
     */
    public function scopeForFloor($query, int $floorNumber)
    {
        return $query->where('floor_number', $floorNumber);
    }
}
