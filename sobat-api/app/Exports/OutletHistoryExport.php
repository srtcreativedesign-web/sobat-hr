<?php

namespace App\Exports;

use App\Models\Attendance;
use App\Models\Organization;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithCustomStartCell;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Events\AfterSheet;

class OutletHistoryExport implements FromCollection, WithHeadings, WithMapping, ShouldAutoSize, WithCustomStartCell, WithEvents
{
    protected $organizationId;
    protected $date;
    protected $organization;

    public function __construct($organizationId, $date)
    {
        $this->organizationId = $organizationId;
        $this->date = $date;
        $this->organization = Organization::find($organizationId);
    }

    public function collection()
    {
        return Attendance::with('employee:id,full_name,employee_code')
            ->where('outlet_id', $this->organizationId)
            ->where('date', $this->date)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function startCell(): string
    {
        return 'A4';
    }

    public function headings(): array
    {
        return [
            'ID Karyawan',
            'Nama Lengkap',
            'Tanggal',
            'Check In',
            'Check Out',
            'Status',
        ];
    }

    public function map($row): array
    {
        $checkIn = $row->check_in ? Carbon::parse($row->check_in)->format('H:i:s') : '-';
        $checkOut = $row->check_out ? Carbon::parse($row->check_out)->format('H:i:s') : '-';

        return [
            $row->employee->employee_code ?? '-',
            $row->employee->full_name ?? '-',
            Carbon::parse($row->date)->format('d/m/Y'),
            $checkIn,
            $checkOut,
            $row->status,
        ];
    }

    public function registerEvents(): array
    {
        return [
            AfterSheet::class => function(AfterSheet $event) {
                $sheet = $event->sheet->getDelegate();
                
                $outletName = $this->organization ? $this->organization->name : 'Outlet';
                $formattedDate = Carbon::parse($this->date)->translatedFormat('d F Y');

                $sheet->setCellValue('A1', 'Riwayat Absensi - ' . $outletName);
                $sheet->mergeCells('A1:F1');
                $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
                
                $sheet->setCellValue('A2', 'Tanggal: ' . $formattedDate);
                $sheet->mergeCells('A2:F2');

                // Header styling
                $sheet->getStyle('A4:F4')->getFont()->setBold(true);
                $sheet->getStyle('A4:F4')->getFill()->setFillType(\PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID);
                $sheet->getStyle('A4:F4')->getFill()->getStartColor()->setARGB('FFEFEFEF');
            },
        ];
    }
}
