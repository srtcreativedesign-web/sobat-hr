<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Division extends Model
{
    use HasFactory;
    
    protected $fillable = ['name', 'code', 'description', 'department_id'];

    /**
     * Relationships
     */
    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    public function jobPositions()
    {
        return $this->hasMany(JobPosition::class);
    }
}
