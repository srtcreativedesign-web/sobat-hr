<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RequestModel extends Model
{
    use HasFactory;

    protected $table = 'requests';

    protected $fillable = [
        'employee_id',
        'type',
        'title',
        'description',
        'start_date',
        'end_date',
        'amount',
        'status',
        'submitted_at',
        'attachments',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'amount' => 'decimal:2',
        'submitted_at' => 'datetime',
        'attachments' => 'array',
    ];

    /**
     * Relationships
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function approvals()
    {
        return $this->hasMany(Approval::class, 'request_id');
    }
}
