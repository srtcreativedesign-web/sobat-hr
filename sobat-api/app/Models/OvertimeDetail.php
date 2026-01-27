<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OvertimeDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'date',
        'start_time',
        'end_time',
        'duration',
        'reason',
    ];

    protected $casts = [
        'date' => 'date',
    ];
}
