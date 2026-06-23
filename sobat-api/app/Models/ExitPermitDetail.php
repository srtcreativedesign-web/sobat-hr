<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExitPermitDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'permit_type',
        'destination',
        'vehicle_plate',
        'date',
        'start_time',
        'end_time',
        'signature',
    ];

    public function request()
    {
        return $this->belongsTo(RequestModel::class, 'request_id');
    }
}
