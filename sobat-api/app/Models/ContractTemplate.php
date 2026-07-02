<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContractTemplate extends Model
{
    protected $fillable = [
        'name',
        'content',
        'settings',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'settings' => 'array',
    ];
}
