<?php

namespace App\Exports;

use App\Models\Attendance;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use Carbon\Carbon;

use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Illuminate\Http\Request;

class AttendanceExport implements FromQuery, WithHeadings, WithMapping, WithStyles
{
    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function query()
    {
        $query = Attendance::with(['employee.organization']);

        if ($this->request->has('employee_id') && $this->request->employee_id) {
            $query->where('employee_id', $this->request->employee_id);
        }

        // Date Range Filter
        if ($this->request->has('start_date') && $this->request->start_date) {
            $query->whereDate('date', '>=', $this->request->start_date);
        }
        if ($this->request->has('end_date') && $this->request->end_date) {
            $query->whereDate('date', '<=', $this->request->end_date);
        }
        
        // Fallback to single date if provided (backward compatibility)
        if (!$this->request->has('start_date') && $this->request->has('date') && $this->request->date) {
            $query->whereDate('date', $this->request->date);
        }

        // Division Filter
        if ($this->request->has('division_id') && $this->request->division_id) {
            $query->whereHas('employee', function ($q) {
                $q->where('organization_id', $this->request->division_id);
            });
        }

        if ($this->request->has('status') && $this->request->status) {
            $query->where('status', $this->request->status);
        }

        // Apply month/year filter if present (for reports)
        if ($this->request->has('month') && $this->request->month) {
            $query->whereMonth('date', $this->request->month);
        }
        if ($this->request->has('year') && $this->request->year) {
            $query->whereYear('date', $this->request->year);
        }

        return $query->orderBy('date', 'desc');
    }

    public function headings(): array
    {
        return [
            'ID',
            'Kode Karyawan',
            'Nama Karyawan',
            'Departemen/Divisi',
            'Tanggal',
            'Jam Masuk',
            'Jam Keluar',
            'Total Jam Kerja',
            'Terlambat (Menit)',
            'Status',
            'Lokasi',
            'Catatan',
        ];
    }

    public function map($attendance): array
    {
        return [
            $attendance->id,
            $attendance->employee->employee_code ?? '-',
            $attendance->employee->full_name ?? '-',
            $attendance->employee->organization->name ?? '-',
            $attendance->date->format('Y-m-d'),
            $attendance->check_in,
            $attendance->check_out,
            $attendance->work_hours,
            $attendance->late_duration,
            strtoupper($attendance->status),
            $attendance->location_address,
            $attendance->notes,
        ];
    }

    public function styles(Worksheet $sheet)
    {
        // Get all rows
        $rows = $sheet->getHighestRow();
        
        // Loop through rows (start from row 2 because 1 is header)
        for ($row = 2; $row <= $rows; $row++) {
            // Get Check In time (Column F / 6)
            $checkInCell = $sheet->getCellByColumnAndRow(6, $row)->getValue();
            
            // Logic for Color
            $color = '00FF00'; // Green (default safe)
            
            if ($checkInCell) {
                // Parse Check In time
                // Assuming format H:i or H:i:s
                try {
                    $time = Carbon::createFromFormat('H:i:s', $checkInCell);
                    $limit = Carbon::createFromFormat('H:i:s', '08:05:00');
                    
                    if ($time->gt($limit)) {
                        $color = 'FF0000'; // Red
                    }
                } catch (\Exception $e) {
                     // Try without seconds if failed
                     try {
                        $time = Carbon::createFromFormat('H:i', $checkInCell);
                        $limit = Carbon::createFromFormat('H:i', '08:05');
                        if ($time->gt($limit)) {
                            $color = 'FF0000'; // Red
                        }
                     } catch (\Exception $ex) {
                        // ignore invalid time format
                     }
                }
            } else {
                 // No check in (Absent/Leave)? Keep default or white? 
                 // Requirement specific about check in time > 08:05.
                 // If absent, check in is usually null/empty. Let's make it Neutral/White or skip coloring?
                 // Let's assume red if Absent/No Check In but supposed to adhere to rule? 
                 // Or just skip. Let's skip coloring if no check in.
                 $color = null; 
            }
            
            // Apply to Status Column (Column J / 10)
            if ($color) {
                $sheet->getStyleByColumnAndRow(10, $row)->getFill()
                    ->setFillType(Fill::FILL_SOLID)
                    ->getStartColor()->setARGB($color);
            }
        }
    }
}
