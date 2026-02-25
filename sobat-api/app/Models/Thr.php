<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Thr extends Model
{
    use \Illuminate\Database\Eloquent\Factories\HasFactory;

    protected $fillable = [
        'employee_id',
        'year',
        'amount',
        'tax',
        'net_amount',
        'status',
        'details',
        'approval_signature',
        'signer_name',
        'approved_by',
        'paid_at',
    ];

    protected $casts = [
        'details' => 'array',
        'amount' => 'decimal:2',
        'tax' => 'decimal:2',
        'net_amount' => 'decimal:2',
        'paid_at' => 'datetime',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
