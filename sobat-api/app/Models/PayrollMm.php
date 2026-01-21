<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PayrollMm extends Model
{
    protected $table = 'payrolls_mm';
    
    protected $guarded = ['id'];
    
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
