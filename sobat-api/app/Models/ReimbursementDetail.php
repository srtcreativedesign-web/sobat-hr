<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReimbursementDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'date',
        'title',
        'description',
        'amount',
        'attachment',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'date' => 'date',
        'attachment' => 'array',
    ];
}
