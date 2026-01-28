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
        'reason', // Legacy column support
        'start_date',
        'end_date',
        'amount',
        'status',
        'submitted_at',
        'attachments',
    ];

    protected $appends = ['detail'];

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
        return $this->morphMany(Approval::class, 'approvable');
    }

    public function leaveDetail()
    {
        return $this->hasOne(LeaveDetail::class, 'request_id');
    }

    public function overtimeDetail()
    {
        return $this->hasOne(OvertimeDetail::class, 'request_id');
    }

    public function sickLeaveDetail()
    {
        return $this->hasOne(SickLeaveDetail::class, 'request_id');
    }

    public function businessTripDetail()
    {
        return $this->hasOne(BusinessTripDetail::class, 'request_id');
    }

    public function reimbursementDetail()
    {
        return $this->hasOne(ReimbursementDetail::class, 'request_id');
    }

    public function assetDetail()
    {
        return $this->hasOne(AssetDetail::class, 'request_id');
    }

    public function resignationDetail()
    {
        return $this->hasOne(ResignationDetail::class, 'request_id');
    }

    public function getDetailAttribute()
    {
        switch ($this->type) {
            case 'leave':
                // Check if it's sick leave based on title? Or should we use a subtype column?
                // For now, assume 'leave' type might be LeaveDetail.
                // But wait, create_submission_screen sends 'leave' for Cuti and Sakit.
                // We need to distinguish.
                return $this->leaveDetail ?? $this->sickLeaveDetail; 
            case 'sick_leave':
                return $this->sickLeaveDetail;
            case 'overtime':
                return $this->overtimeDetail;
            case 'reimbursement': // used for Reimburse
                return $this->reimbursementDetail;
            case 'asset':
                return $this->assetDetail;
            case 'resignation':
                return $this->resignationDetail;
            case 'business_trip':
                return $this->businessTripDetail;
            default:
                return null;
        }
    }
}
