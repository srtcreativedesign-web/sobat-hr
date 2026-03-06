<?php

namespace App\Exports;

use App\Models\RequestModel;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\FromQuery;
use Illuminate\Http\Request;
use App\Traits\ExcelSanitizer;

class OvertimeExport implements FromQuery, WithHeadings, WithMapping
{
    use ExcelSanitizer;

    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function query()
    {
        $query = RequestModel::query()
            ->with(['employee', 'overtimeDetail'])
            ->where('type', 'overtime')
            ->where('status', 'approved');

        if ($this->request->has('department') && $this->request->department) {
            $dept = $this->request->department;
            $query->whereHas('employee', function($q) use ($dept) {
                $q->where('department', $dept);
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
        return $this->sanitizeArray([
            $request->employee ? $request->employee->full_name : '-',
            $request->employee ? $request->employee->department : '-',
            $request->start_date ? $request->start_date->format('Y-m-d') : '-',
            $request->overtimeDetail ? $request->overtimeDetail->start_time : '-',
            $request->overtimeDetail ? $request->overtimeDetail->end_time : '-',
            $request->amount ? ($request->amount * 60) : ($request->overtimeDetail ? $request->overtimeDetail->duration : '-'), // amount is hours usually
            $request->reason,
            $request->status,
        ]);
    }
}
