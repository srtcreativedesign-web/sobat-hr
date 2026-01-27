<?php

namespace App\Traits;

use App\Models\Approval;
use App\Models\Employee;

trait HasApprovals
{
    public function approvals()
    {
        return $this->morphMany(Approval::class, 'approvable');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
