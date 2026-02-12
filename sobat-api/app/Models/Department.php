<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Department extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'code', 'description'];

    /**
     * Get the divisions for the department.
     */
    public function divisions()
    {
        return $this->hasMany(Division::class);
    }
}
