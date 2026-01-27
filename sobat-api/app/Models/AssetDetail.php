<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AssetDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'brand',
        'specification',
        'amount',
        'is_urgent',
        'reason',
        'attachment',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'is_urgent' => 'boolean',
        'attachment' => 'array',
    ];
}
