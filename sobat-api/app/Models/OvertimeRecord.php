<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Employee;
use App\Models\RequestModel;

class OvertimeRecord extends Model
{
    use HasFactory;
    
    protected $fillable = [
        'employee_id',
        'request_id',
        'date',
        'start_time',
        'end_time',
        'duration',
        'reason',
        'approved_at',
    ];

    protected $casts = [
        'date' => 'date',
        'approved_at' => 'datetime',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
    
    public function request()
    {
        return $this->belongsTo(RequestModel::class, 'request_id');
    }
}
