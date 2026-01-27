<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BusinessTripDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'destination',
        'start_date',
        'end_date',
        'purpose',
        'budget',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'budget' => 'decimal:2',
    ];
}
