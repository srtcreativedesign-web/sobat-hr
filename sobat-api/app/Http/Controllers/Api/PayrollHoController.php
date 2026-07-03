<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Services\GroqAiService;
use Carbon\Carbon;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class PayrollHoController extends Controller implements HasMiddleware
{
    public static function middleware(): array
    {
        return [
            new Middleware(function ($request, $next) {
                if (auth()->check() && auth()->user()->role && in_array(strtolower(auth()->user()->role->name), ['admin_hr', 'personalia'])) {
                    abort(403, 'Anda tidak memiliki akses ke Payroll Head Office.');
                }
                return $next($request);
            }),
        ];
    }

    /**
     * Display a listing of HO payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = Payroll::with(['employee', 'employee.division']);

        // Filter out retail divisions from the generic payrolls table
        // This ensures the Mobile App (which calls /payrolls/ho) doesn't get duplicate retail employees
        $query->where(function($q) {
            $q->whereNull('details')
              ->orWhere('details', '')
              ->orWhere('details', 'not like', '%"division_type"%');
        });

        // Scope access
        $roleName = $user->role ? strtolower($user->role->name) : '';
        if (!in_array($roleName, ['admin', 'super_admin', 'hr'])) {
            $employeeId = $user->employee ? $user->employee->id : null;
            if ($employeeId) {
                $query->where('employee_id', $employeeId);
                $query->whereIn('status', ['approved', 'paid']);
            } else {
                return response()->json([]);
            }
        }
        
        // Filter
        if ($request->has('period')) {
            $query->where('period', $request->period);
        } elseif ($request->has('month') && $request->has('year') && $request->month != 0 && $request->year != 0) {
            $periodString = sprintf('%04d-%02d', $request->year, $request->month);
            $query->where('period', $periodString);
        } elseif (!$request->has('period') && $request->has('year') && !empty($request->year) && $request->year !== 'null') {
            $query->where('period', 'like', $request->year . '-%');
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        $payrolls = $query->orderBy('period', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        // Format details
        $payrolls->getCollection()->transform(function ($payroll) {
            return $this->formatPayroll($payroll);
        });
        
        return response()->json($payrolls);
    }

    /**
     * Show single payroll
     */
    public function show($id)
    {
        $payroll = Payroll::with(['employee', 'employee.division'])->findOrFail($id);

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, ['admin', 'super_admin', 'hr', 'admin_cabang']);

        if (!$isAdmin) {
            if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        }

        return response()->json($this->formatPayroll($payroll));
    }

    /**
     * Helper to format payroll data from JSON details
     */
    private function formatPayroll($payroll)
    {
        $details = $payroll->details ?? [];
        $deductions = $details['deductions'] ?? [];
        $formatted = $payroll->toArray();

        // Safe access helper
        $get = fn($key, $default = 0) => $details[$key] ?? $default;
        
        $formatted['allowances'] = [
            'Kehadiran' => [
                'rate' => $get('attendance_rate'),
                'amount' => $get('attendance_allowance'),
            ],
            'Transport' => [
                'rate' => $get('transport_rate'),
                'amount' => $get('transport_allowance'),
            ],
            'Tunjangan Kesehatan' => $get('health_allowance'),
            'Tunjangan Jabatan' => $get('position_allowance'),
            'Lembur' => [
                'rate' => $get('overtime_rate'),
                'hours' => $get('overtime_hours'),
                'amount' => $get('overtime_amount') ?: ($payroll->overtime_pay ?? 0),
            ],
            'Insentif Luar Kota' => $get('insentif_luar_kota'),
            'Insentif Kehadiran' => $get('insentif_kehadiran'),
            'Piket & UM Sabtu' => $get('piket_um_sabtu'),
            'Adjustment' => $get('adjustment'),
            'THR/Bonus' => $get('holiday_allowance'),
        ];

        $formatted['deductions'] = [
            'Potongan Absen' => $deductions['absent'] ?? 0,
            'Terlambat' => $deductions['late'] ?? 0,
            'Selisih SO' => $deductions['shortage'] ?? 0,
            'Pinjaman/Kasbon' => $deductions['loan'] ?? 0,
            'Adm Bank' => $deductions['bank_fee'] ?? 0,
            'BPJS TK' => $deductions['bpjs_tk'] ?? 0,
            'ALFA' => $deductions['alfa'] ?? 0,
            'Admin Bank & EWA' => $get('ewa'),
        ];
        
        $formatted['attendance'] = [
             'Hadir' => $get('days_present'),
             'Sakit' => 0, 'Ijin' => 0, 'Alfa' => 0, 'Cuti' => 0
        ];

        return $formatted;
    }

        public function parseHeaders(Request $request)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,xls']);
        
        // Exact column mapping based on "ho utk payslip.xlsx"
        $headers = [
            'A' => 'No',
            'B' => 'NIK',
            'C' => 'NAMA',
            'D' => 'Nomor Rekening',
            'E' => 'GP (Gaji Pokok)',
            'F' => 'JML HR MASUK',
            'G' => 'IJIN',
            'H' => 'Transport @hari',
            'I' => 'Transport (Total)',
            'J' => 'Uang Kehadiran @hari',
            'K' => 'Uang Kehadiran (Total)',
            'L' => 'JAM LBR',
            'M' => 'Lembur @ jam',
            'N' => 'Uang Lembur (Total)',
            'O' => 'Gaji (Subtotal)',
            'P' => 'Tunjangan Jabatan',
            'Q' => 'Tunjangan Kesehatan',
            'R' => 'Insentif Luar Kota',
            'S' => 'Insentif Kehadiran',
            'T' => 'Adj gaji',
            'U' => 'Piket dan UM sabtu',
            'V' => 'Gaji diterima (Bruto)',
            'W' => 'Kasbon',
            'X' => 'BPJS',
            'Y' => 'Admin bank dan ewa',
            'Z' => 'Total (Netto)'
        ];
        
        $default_mapping = [
            'employee_name' => 'C',
            'account_number' => 'D',
            'basic_salary' => 'E',
            'days_present' => 'F',
            'days_permission' => 'G',
            'transport_rate' => 'H',
            'transport_allowance' => 'I',
            'attendance_rate' => 'J',
            'attendance_allowance' => 'K',
            'overtime_hours' => 'L',
            'overtime_rate' => 'M',
            'overtime_amount' => 'N',
            'position_allowance' => 'P',
            'health_allowance' => 'Q',
            'insentif_luar_kota' => 'R',
            'insentif_kehadiran' => 'S',
            'adjustment' => 'T',
            'piket_um_sabtu' => 'U',
            'deduction_kasbon' => 'W',
            'deduction_bpjs' => 'X',
            'deduction_admin' => 'Y',
            'gross_salary' => 'V',
            'net_salary' => 'Z'
        ];
        
        $expected_fields = [
            ['key' => 'employee_name', 'label' => 'Nama Karyawan'],
            ['key' => 'account_number', 'label' => 'Nomor Rekening'],
            ['key' => 'basic_salary', 'label' => 'Gaji Pokok'],
            ['key' => 'days_present', 'label' => 'Jml Hr Masuk'],
            ['key' => 'days_permission', 'label' => 'Ijin'],
            ['key' => 'transport_rate', 'label' => 'Transport @hari'],
            ['key' => 'transport_allowance', 'label' => 'Transport (Total)'],
            ['key' => 'attendance_rate', 'label' => 'Uang Kehadiran @hari'],
            ['key' => 'attendance_allowance', 'label' => 'Uang Kehadiran (Total)'],
            ['key' => 'overtime_hours', 'label' => 'Jam Lembur'],
            ['key' => 'overtime_rate', 'label' => 'Lembur @ Jam'],
            ['key' => 'overtime_amount', 'label' => 'Uang Lembur (Total)'],
            ['key' => 'position_allowance', 'label' => 'Tunjangan Jabatan'],
            ['key' => 'health_allowance', 'label' => 'Tunjangan Kesehatan'],
            ['key' => 'insentif_luar_kota', 'label' => 'Insentif Luar Kota'],
            ['key' => 'insentif_kehadiran', 'label' => 'Insentif Kehadiran'],
            ['key' => 'adjustment', 'label' => 'Adj Gaji'],
            ['key' => 'piket_um_sabtu', 'label' => 'Piket dan UM Sabtu'],
            ['key' => 'gross_salary', 'label' => 'Gaji Diterima (Bruto)'],
            ['key' => 'deduction_kasbon', 'label' => 'Kasbon'],
            ['key' => 'deduction_bpjs', 'label' => 'BPJS'],
            ['key' => 'deduction_admin', 'label' => 'Admin Bank dan EWA'],
            ['key' => 'net_salary', 'label' => 'Total (Netto)']
        ];
        
        return response()->json([
            'requiresMapping' => true,
            'headers' => $headers,
            'default_mapping' => $default_mapping,
            'expected_fields' => $expected_fields,
            'headerRowIndex' => 7,
            'file_name' => $request->file('file')->getClientOriginalName()
        ]);
    }

    public function simulateImport(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
            'mapping' => 'required|string',
            'headerRowIndex' => 'required|integer',
        ]);
        
        $mapping = json_decode($request->mapping, true);
        $file = $request->file('file');
        
        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getSheet(0);
            
            $dataRows = [];
            $highestRow = $sheet->getHighestRow();
            
            $startRow = 8;
            for ($r = $startRow; $r <= $highestRow; $r++) {
                $nameCol = $mapping['employee_name'] ?? 'C';
                $nameVal = trim((string)$sheet->getCell($nameCol . $r)->getCalculatedValue());
                if (!empty($nameVal) && !is_numeric($nameVal) && strtolower($nameVal) !== 'nama') {
                    $startRow = $r;
                    break;
                }
            }
            
            $getVal = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                $val = $sheet->getCell($col . $row)->getCalculatedValue();
                if (is_numeric($val)) return (float)$val;
                return 0;
            };

            for ($row = $startRow; $row <= min($startRow + 10, $highestRow); $row++) {
                $nameCol = $mapping['employee_name'] ?? 'C';
                $name = trim((string)$sheet->getCell($nameCol . $row)->getCalculatedValue());
                if (empty($name) || is_numeric($name)) continue;
                
                $dataRows[] = [
                    'employee_name' => $name,
                    'period' => $request->period ?? date('Y-m'),
                    'account_number' => $mapping['account_number'] ? trim((string)$sheet->getCell($mapping['account_number'] . $row)->getCalculatedValue()) : '',
                    'basic_salary' => $getVal($mapping['basic_salary'] ?? null, $row),
                    'days_present' => $getVal($mapping['days_present'] ?? null, $row),
                    'days_permission' => $getVal($mapping['days_permission'] ?? null, $row),
                    'transport_allowance' => $getVal($mapping['transport_allowance'] ?? null, $row),
                    'attendance_allowance' => $getVal($mapping['attendance_allowance'] ?? null, $row),
                    'overtime_amount' => $getVal($mapping['overtime_amount'] ?? null, $row),
                    'position_allowance' => $getVal($mapping['position_allowance'] ?? null, $row),
                    'health_allowance' => $getVal($mapping['health_allowance'] ?? null, $row),
                    'insentif_luar_kota' => $getVal($mapping['insentif_luar_kota'] ?? null, $row),
                    'insentif_kehadiran' => $getVal($mapping['insentif_kehadiran'] ?? null, $row),
                    'adjustment' => $getVal($mapping['adjustment'] ?? null, $row),
                    'piket_um_sabtu' => $getVal($mapping['piket_um_sabtu'] ?? null, $row),
                    'deductions' => [
                        'kasbon' => $getVal($mapping['deduction_kasbon'] ?? null, $row),
                        'bpjs' => $getVal($mapping['deduction_bpjs'] ?? null, $row),
                        'admin' => $getVal($mapping['deduction_admin'] ?? null, $row)
                    ],
                    'gross_salary' => $getVal($mapping['gross_salary'] ?? null, $row),
                    'net_salary' => $getVal($mapping['net_salary'] ?? null, $row),
                ];
            }
            
            return response()->json([
                'message' => 'Simulasi berhasil',
                'rows' => $dataRows,
                'total_rows' => $highestRow - $startRow + 1
            ]);
            
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }
    
    public function import(Request $request)
    {
        return response()->json(['message' => 'Gunakan alur parse-headers dan save.'], 400);
    }
    
    public function saveImport(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls',
            'mapping' => 'required|string',
            'headerRowIndex' => 'required|integer',
        ]);
        
        $mapping = json_decode($request->mapping, true);
        $file = $request->file('file');
        
        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getSheet(0);
            
            $highestRow = $sheet->getHighestRow();
            $startRow = 8;
            for ($r = $startRow; $r <= $highestRow; $r++) {
                $nameCol = $mapping['employee_name'] ?? 'C';
                $nameVal = trim((string)$sheet->getCell($nameCol . $r)->getCalculatedValue());
                if (!empty($nameVal) && !is_numeric($nameVal) && strtolower($nameVal) !== 'nama') {
                    $startRow = $r;
                    break;
                }
            }
            
            $getVal = function($col, $row) use ($sheet) {
                if (!$col) return 0;
                $val = $sheet->getCell($col . $row)->getCalculatedValue();
                if (is_numeric($val)) return (float)$val;
                return 0;
            };

            $saved = 0;
            $errors = [];
            
            for ($row = $startRow; $row <= $highestRow; $row++) {
                $nameCol = $mapping['employee_name'] ?? 'C';
                $name = trim((string)$sheet->getCell($nameCol . $row)->getCalculatedValue());
                if (empty($name) || is_numeric($name)) continue;
                
                $employee = \App\Models\Employee::whereRaw('LOWER(full_name) = ?', [strtolower($name)])->first();
                if (!$employee) {
                    $errors[] = "Baris $row: Karyawan '$name' tidak ditemukan di database.";
                    continue;
                }
                
                $currentPeriod = $request->period ?? date('Y-m');
                
                $transport = $getVal($mapping['transport_allowance'] ?? null, $row);
                $attendance = $getVal($mapping['attendance_allowance'] ?? null, $row);
                $position = $getVal($mapping['position_allowance'] ?? null, $row);
                $health = $getVal($mapping['health_allowance'] ?? null, $row);
                $insentif_luar = $getVal($mapping['insentif_luar_kota'] ?? null, $row);
                $insentif_hadir = $getVal($mapping['insentif_kehadiran'] ?? null, $row);
                $adj = $getVal($mapping['adjustment'] ?? null, $row);
                $piket = $getVal($mapping['piket_um_sabtu'] ?? null, $row);
                
                $allowancesTotal = $transport + $attendance + $position + $health + $insentif_luar + $insentif_hadir + $adj + $piket;
                
                $kasbon = abs($getVal($mapping['deduction_kasbon'] ?? null, $row));
                $bpjs = abs($getVal($mapping['deduction_bpjs'] ?? null, $row));
                $admin = abs($getVal($mapping['deduction_admin'] ?? null, $row));
                
                $deductionsTotal = $kasbon + $bpjs + $admin;
                
                $grossExcel = $getVal($mapping['gross_salary'] ?? null, $row);
                $netExcel = $getVal($mapping['net_salary'] ?? null, $row);
                $basic = $getVal($mapping['basic_salary'] ?? null, $row);
                $overtime = $getVal($mapping['overtime_amount'] ?? null, $row);
                
                $gross = $grossExcel > 0 ? $grossExcel : ($basic + $allowancesTotal + $overtime);
                $net = $netExcel > 0 ? $netExcel : ($gross - $deductionsTotal);
                
                $details = [
                    'account_number' => $mapping['account_number'] ? trim((string)$sheet->getCell($mapping['account_number'] . $row)->getCalculatedValue()) : '',
                    'days_present' => $getVal($mapping['days_present'] ?? null, $row),
                    'days_permission' => $getVal($mapping['days_permission'] ?? null, $row),
                    'transport_rate' => $getVal($mapping['transport_rate'] ?? null, $row),
                    'transport_allowance' => $transport,
                    'attendance_rate' => $getVal($mapping['attendance_rate'] ?? null, $row),
                    'attendance_allowance' => $attendance,
                    'overtime_hours' => $getVal($mapping['overtime_hours'] ?? null, $row),
                    'overtime_rate' => $getVal($mapping['overtime_rate'] ?? null, $row),
                    'overtime_amount' => $overtime,
                    'position_allowance' => $position,
                    'health_allowance' => $health,
                    'insentif_luar_kota' => $insentif_luar,
                    'insentif_kehadiran' => $insentif_hadir,
                    'piket_um_sabtu' => $piket,
                    'adjustment' => $adj,
                    'deduction_kasbon' => $kasbon,
                    'deduction_bpjs' => $bpjs,
                    'deduction_admin' => $admin,
                ];
                
                \App\Models\Payroll::updateOrCreate(
                    ['employee_id' => $employee->id, 'period' => $currentPeriod],
                    [
                        'type' => 'HO',
                        'outlet_name' => 'Head Office',
                        'basic_salary' => $basic,
                        'allowances' => $allowancesTotal,
                        'overtime_pay' => $overtime,
                        'gross_salary' => $gross,
                        'bpjs_kesehatan' => $bpjs,
                        'bpjs_ketenagakerjaan' => 0,
                        'other_deductions' => $kasbon + $admin,
                        'total_deductions' => $deductionsTotal,
                        'net_salary' => $net,
                        'details' => $details,
                        'status' => 'pending',
                    ]
                );
                
                $saved++;
            }
            
            return response()->json([
                'message' => 'Import berhasil diselesaikan.',
                'saved' => $saved,
                'errors' => $errors
            ]);
            
        } catch (\Exception $e) {
            \Log::error('HO Payroll Save Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

public function generatePayslip($id)
    {
        $payroll = Payroll::with(['employee'])->findOrFail($id);

        // --- IDOR GUARD ---
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        $isAdmin = in_array($roleName, ['admin', 'super_admin', 'hr', 'admin_cabang']);

        if (!$isAdmin) {
            if (!$user->employee || $user->employee->id !== $payroll->employee_id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        }
        
        $aiMessage = null;
        try {
            $groqService = new GroqAiService();
            $aiMessage = $groqService->generatePayslipMessage([
                'employee_name' => $payroll->employee->full_name,
                'period' => date('F Y', strtotime($payroll->period . '-01')),
                'basic_salary' => $payroll->basic_salary,
                'overtime' => $payroll->overtime_pay ?? 0,
                'net_salary' => $payroll->net_salary,
                'join_date' => $payroll->employee->join_date,
            ]);
        } catch (\Exception $e) {}

        $pdf = Pdf::loadView('payslips.ho', [
            'payroll' => $payroll,
            'aiMessage' => $aiMessage,
            'employee' => $payroll->employee,
            'details' => $payroll->details // Pass details explicitly helper
        ]);

        $pdf->setPaper('a4', 'portrait');
        $filename = 'Slip_Gaji_HO_' . str_replace(' ', '_', $payroll->employee->full_name) . '_' . $payroll->period . '.pdf';

        return $pdf->download($filename);
    }
    
    /**
     * Update Status
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|in:draft,approved,paid']);
        $payroll = Payroll::findOrFail($id);
        
        $data = ['status' => $request->status];
        if ($request->status === 'approved' && $request->has('approval_signature')) {
            $data['approval_signature'] = $request->approval_signature;
            $data['signer_name'] = $request->signer_name;
            $data['notes'] = $request->notes;
            $data['approved_by'] = auth()->id();
        }
        
        $payroll->update($data);
        return response()->json(['message' => 'Status updated', 'payroll' => $payroll]);
    }
}
