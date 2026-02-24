<?php

namespace App\Exports;

use App\Models\RequestModel;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\FromQuery;
use Illuminate\Http\Request;

class OvertimeExport implements FromQuery, WithHeadings, WithMapping
{
    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function query()
    {
        $query = RequestModel::query()
            ->with(['employee.organization', 'overtimeDetail'])
            ->where('type', 'overtime')
            ->where('status', 'approved');

        if ($this->request->has('organization_id') && $this->request->organization_id) {
            $orgId = $this->request->organization_id;
            $query->whereHas('employee', function($q) use ($orgId) {
                $q->where('organization_id', $orgId);
            });
        }

        if ($this->request->has('search') && $this->request->search) {
            $search = $this->request->search;
            $query->whereHas('employee', function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('employee_code', 'like', "%{$search}%");
            });
        }
        
        return $query->orderBy('start_date', 'desc');
    }

    public function headings(): array
    {
        return [
            'Employee Name',
            'Division',
            'Date',
            'Start Time',
            'End Time',
            'Duration (Minutes)',
            'Reason',
            'Status',
        ];
    }

    public function map($request): array
    {
        return [
            $request->employee ? $request->employee->full_name : '-',
            $request->employee && $request->employee->organization ? $request->employee->organization->name : '-',
            $request->start_date ? $request->start_date->format('Y-m-d') : '-',
            $request->overtimeDetail ? $request->overtimeDetail->start_time : '-',
            $request->overtimeDetail ? $request->overtimeDetail->end_time : '-',
            $request->amount ? ($request->amount * 60) : ($request->overtimeDetail ? $request->overtimeDetail->duration : '-'), // amount is hours usually
            $request->reason,
            $request->status,
        ];
    }
}
