<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Thr extends Model
{
    use \Illuminate\Database\Eloquent\Factories\HasFactory;

    protected $fillable = [
        'employee_id',
        'division',
        'year',
        'amount',
        'status',
        'details',
    ];

    protected $casts = [
        'details' => 'array',
        'amount' => 'decimal:2',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
