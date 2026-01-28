<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ResignationDetail extends Model
{
    use HasFactory;

    protected $table = 'resignation_details';

    protected $fillable = [
        'request_id',
        'last_working_date',
        'resign_type',
        'handover_notes',
    ];

    protected $casts = [
        'last_working_date' => 'date',
    ];

    public function request()
    {
        return $this->belongsTo(RequestModel::class, 'request_id');
    }
}
