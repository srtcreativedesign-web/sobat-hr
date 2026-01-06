<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'organization_id',
        'start_time',
        'end_time',
        'days',
    ];

    protected $casts = [
        'start_time' => 'datetime:H:i',
        'end_time' => 'datetime:H:i',
    ];

    /**
     * Relationships
     */
    public function organization()
    {
        return $this->belongsTo(Organization::class);
    }

    public function employees()
    {
        return $this->hasMany(Employee::class);
    }

    /**
     * Accessor for days array
     */
    public function getDaysAttribute($value)
    {
        return json_decode($value, true);
    }

    /**
     * Mutator for days array
     */
    public function setDaysAttribute($value)
    {
        $this->attributes['days'] = is_array($value) ? json_encode($value) : $value;
    }
}
