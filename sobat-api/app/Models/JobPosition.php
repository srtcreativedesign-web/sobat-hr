<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JobPosition extends Model
{
    protected $fillable = [
        'name',
        'code',
        'division_id',
        'level',
        'track',
        'parent_position_id',
    ];

    /**
     * Relationships
     */
    public function division()
    {
        return $this->belongsTo(Division::class);
    }

    public function parentPosition()
    {
        return $this->belongsTo(JobPosition::class, 'parent_position_id');
    }

    public function childPositions()
    {
        return $this->hasMany(JobPosition::class, 'parent_position_id');
    }
}
