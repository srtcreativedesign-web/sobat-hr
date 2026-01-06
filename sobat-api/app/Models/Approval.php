<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Approval extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'approver_id',
        'level',
        'status',
        'notes',
        'approved_at',
    ];

    protected $casts = [
        'level' => 'integer',
        'approved_at' => 'datetime',
    ];

    /**
     * Relationships
     */
    public function request()
    {
        return $this->belongsTo(RequestModel::class, 'request_id');
    }

    public function approver()
    {
        return $this->belongsTo(Employee::class, 'approver_id');
    }
}
