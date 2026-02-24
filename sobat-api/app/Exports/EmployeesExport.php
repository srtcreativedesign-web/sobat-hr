<?php

namespace App\Exports;

use App\Models\Employee;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Illuminate\Http\Request;

class EmployeesExport implements FromQuery, WithHeadings, WithMapping, WithStyles
{
    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function query()
    {
        $query = Employee::with(['organization', 'user']);

        // Division Filter
        if ($this->request->has('organization_id') && $this->request->organization_id) {
            $query->where('organization_id', $this->request->organization_id);
        }

        // Status Filter
        if ($this->request->has('status') && $this->request->status) {
            $query->where('status', $this->request->status);
        }

        return $query->orderBy('full_name', 'asc');
    }

    public function headings(): array
    {
        return [
            'ID',
            'Kode Karyawan',
            'Nama Lengkap',
            'Email',
            'No. Telepon',
            'Jenis Kelamin',
            'Tempat Lahir',
            'Tanggal Lahir',
            'Agama',
            'Status Perkawinan',
            'Pendidikan Terakhir',
            'Divisi/Organisasi',
            'Jabatan',
            'Status Karyawan',
            'Status Kepegawaian',
            'Tanggal Bergabung',
            'Tanggal Berakhir Kontrak',
            'Gaji Pokok',
            'NIK (KTP)',
            'NPWP',
            'Status PTKP',
            'No. Rekening',
            'Nama Bank',
            'Nama Pemilik Rekening',
            'Nama Ayah',
            'Nama Ibu',
            'Nama Pasangan',
            'Kontak Darurat',
            'Alamat KTP',
            'Alamat Domisili',
            'Nama Atasan',
        ];
    }

    public function map($employee): array
    {
        // Handle education field (can be JSON object or string)
        $education = $employee->education;
        if (is_array($education) || is_object($education)) {
            $educationArray = (array) $education;
            $educationParts = [];
            foreach (['s3', 's2', 's1', 'd3', 'smk', 'sma', 'smp', 'sd'] as $level) {
                if (!empty($educationArray[$level])) {
                    $educationParts[] = strtoupper($level) . ': ' . $educationArray[$level];
                }
            }
            $education = implode(', ', $educationParts) ?: '-';
        }

        return [
            $employee->id,
            $employee->employee_code ?? '-',
            $employee->full_name ?? '-',
            $employee->email ?? '-',
            $employee->phone ?? '-',
            $employee->gender === 'male' ? 'Laki-laki' : ($employee->gender === 'female' ? 'Perempuan' : '-'),
            $employee->place_of_birth ?? '-',
            $employee->birth_date ? date('d/m/Y', strtotime($employee->birth_date)) : '-',
            $employee->religion ?? '-',
            $employee->marital_status ?? '-',
            $education ?? '-',
            $employee->organization->name ?? '-',
            $employee->position ?? '-',
            $employee->status === 'active' ? 'Aktif' : ($employee->status === 'inactive' ? 'Non-Aktif' : ($employee->status === 'resigned' ? 'Resign' : $employee->status ?? '-')),
            $employee->employment_status === 'permanent' ? 'Tetap' : ($employee->employment_status === 'contract' ? 'Kontrak' : ($employee->employment_status === 'probation' ? 'Probation' : $employee->employment_status ?? '-')),
            $employee->join_date ? date('d/m/Y', strtotime($employee->join_date)) : '-',
            $employee->contract_end_date ? date('d/m/Y', strtotime($employee->contract_end_date)) : '-',
            $employee->basic_salary ?? 0,
            $employee->nik ?? '-',
            $employee->npwp ?? '-',
            $employee->ptkp_status ?? '-',
            $employee->bank_account_number ?? '-',
            $employee->bank_name ?? '-',
            $employee->bank_account_name ?? '-',
            $employee->father_name ?? '-',
            $employee->mother_name ?? '-',
            $employee->spouse_name ?? '-',
            $employee->family_contact_number ?? '-',
            $employee->ktp_address ?? '-',
            $employee->current_address ?? '-',
            $employee->supervisor_name ?? '-',
        ];
    }

    public function styles(Worksheet $sheet)
    {
        // Style header row
        $sheet->getStyle('A1:AF1')->applyFromArray([
            'font' => [
                'bold' => true,
                'color' => ['argb' => 'FFFFFF'],
            ],
            'fill' => [
                'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                'startColor' => ['argb' => '462E37'],
            ],
        ]);

        // Auto-size columns
        foreach (range('A', 'Z') as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
        // Additional columns AA-AF
        foreach (['AA', 'AB', 'AC', 'AD', 'AE', 'AF'] as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
    }
}
