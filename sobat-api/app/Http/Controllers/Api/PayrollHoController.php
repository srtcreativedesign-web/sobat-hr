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

class PayrollHoController extends Controller
{
    /**
     * Display a listing of HO payrolls
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        $query = Payroll::with(['employee', 'employee.organization']);

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
        $payroll = Payroll::with(['employee', 'employee.organization'])->findOrFail($id);
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
            'Potongan EWA' => $get('ewa'),
        ];
        
        $formatted['attendance'] = [
             'Hadir' => $get('days_present'),
             'Sakit' => 0, 'Ijin' => 0, 'Alfa' => 0, 'Cuti' => 0
        ];

        return $formatted;
    }

    /**
     * Import HO payroll
     */
    public function import(Request $request)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,xls']);
        $file = $request->file('file');

        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getActiveSheet();
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();

            // Robust Value Getter
            $getCellValue = function($col, $row) use ($sheet) {
                $cell = $sheet->getCell($col . $row);
                $value = $cell->getCalculatedValue();
                if (is_numeric($value)) return (float) $value;
                if (is_string($value)) {
                    $clean = preg_replace('/[^0-9\.\,\-]/', '', $value);
                    $clean = str_replace(',', '.', $clean); // Force dot decimal
                    // Handle trailing negative sign if any, or parentheses
                    if (strpos($value, '(') !== false && strpos($value, ')') !== false) {
                        return -(float) $clean;
                    }
                    return (float) $clean;
                }
                return 0;
            };

            // Detect Header
            $headerRowIndex = -1;
            $maxSearchRow = min(20, $highestRow);
            
            for ($row = 1; $row <= $maxSearchRow; $row++) {
                $rowIterator = $sheet->getRowIterator($row, $row)->current();
                $cellIterator = $rowIterator->getCellIterator();
                $cellIterator->setIterateOnlyExistingCells(false);
                
                foreach ($cellIterator as $cell) {
                    $val = $cell->getValue();
                    if ($val instanceof \PhpOffice\PhpSpreadsheet\RichText\RichText) {
                        $val = $val->getPlainText();
                    }
                    $val = trim((string)$val);

                    if ($val) {
                        $normalized = strtolower($val);
                        if (str_contains($normalized, 'nama karyawan') || 
                            str_contains($normalized, 'employee name') || 
                            str_contains($normalized, 'nama pegawai') ||
                            ($normalized === 'nama')) { // Strict check for short 'nama'
                            
                            $headerRowIndex = $row;
                            Log::info("Header found at Row $row, Col " . $cell->getColumn() . " ($val)");
                            break 2;
                        }
                    }
                }
                
                // Debug log first column of row
                 Log::info("Scanning Row $row: " . $sheet->getCell('A'.$row)->getValue() . " | " . $sheet->getCell('B'.$row)->getValue());
            }

            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format Excel tidak dikenali. Kolom "Nama Karyawan" tidak ditemukan.'], 422);
            }

            // Map Headers dynamically
            // -------------------------------------------------------------------------
            // ROBUST HEADER MAPPING (Combined Keys: Parent + Subheader)
            // -------------------------------------------------------------------------
            $finalMapping = [];
            $normalize = function($str) {
                return strtolower(trim(preg_replace('/\s+/', ' ', $str)));
            };
            
            // Row 1 (Parents)
            $parentMap = [];
            $iter1 = $sheet->getRowIterator($headerRowIndex)->current()->getCellIterator();
            $iter1->setIterateOnlyExistingCells(true);
            foreach ($iter1 as $cell) {
                $val = trim((string)$cell->getValue());
                if ($val) {
                    $col = $cell->getColumn();
                    $parentMap[$col] = $val;
                    $finalMapping[$normalize($val)] = $col; // Add parent key
                }
            }

            // Detect Merged Parent Headers (e.g., "Uang Lembur" spanning multiple cols)
            foreach ($sheet->getMergeCells() as $range) {
                $cells = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::extractAllCellReferencesInRange($range);
                $topLeft = $cells[0]; 
                $val = $sheet->getCell($topLeft)->getValue();
                
                if ($val) {
                     foreach ($cells as $cellRef) {
                         // Check if cell is in Header Row
                         if (strpos($cellRef, (string)$headerRowIndex) !== false) {
                             $col = preg_replace('/[0-9]+/', '', $cellRef);
                             // Only assign parent if not already explicitly set by a value in that cell
                             if (!isset($parentMap[$col])) {
                                 $parentMap[$col] = $val;
                             }
                         }
                     }
                }
            }
            
            // Row 2 (Subheaders) - COMBINE with Parent
            $subHeaderRow = $headerRowIndex + 1;
            if ($subHeaderRow <= $highestRow) {
                $iter2 = $sheet->getRowIterator($subHeaderRow)->current()->getCellIterator();
                $iter2->setIterateOnlyExistingCells(true);
                foreach ($iter2 as $cell) {
                     $val = trim((string)$cell->getValue());
                     $col = $cell->getColumn();
                     
                     if ($val) {
                         // Add generic subheader key (beware ambiguities like 'total')
                         $finalMapping[$normalize($val)] = $col; 
                         
                         // Add Combined Key (Parent + Subheader) -> HIGH PRIORITY
                         if (isset($parentMap[$col])) {
                             $parent = $parentMap[$col];
                             $combined = $parent . ' ' . $val;
                             $finalMapping[$normalize($combined)] = $col;
                         } else {
                             // Try to find parent from previous columns (heuristic for unmerged visual grouping)
                             $cIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($col);
                             for ($search = $cIndex - 1; $search >= 1; $search--) {
                                 $searchCol = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($search);
                                 if (isset($parentMap[$searchCol])) {
                                     $parent = $parentMap[$searchCol];
                                     $combined = $parent . ' ' . $val;
                                     $finalMapping[$normalize($combined)] = $col;
                                     break; // Found nearest left parent
                                 }
                             }
                         }
                     }
                }
            }

            // Helper to find column
            $findCol = function($patterns, $default = null) use ($finalMapping, $normalize) {
                foreach ((array)$patterns as $pat) {
                    $nPat = $normalize($pat);
                    if (isset($finalMapping[$nPat])) return $finalMapping[$nPat];
                }
                return $default;
            };

            // Define Columns Configuration (Once, outside loop)
            $cols = [
                'account' => $findCol(['no rekening', 'account number', 'rekening', 'nomor rekening'], 'C'),
                'present' => $findCol(['jml hr masuk', 'hadir', 'jml hr masuk'], 'E'),
                'basic' => $findCol(['gaji pokok'], null),
                'transport_amt' => $findCol(['transport total', 'uang kehadiran'], null),
                'transport_rate' => $findCol(['transport @hari'], null),
                'attend_amt' => $findCol(['uang kehadiran total', 'uang kehadiran'], null), 
                'attend_rate' => $findCol(['uang kehadiran @hari'], null),
                'health' => $findCol(['tunjangan'], null), 
                'position' => $findCol(['tunjangan jabatan'], null),
                'overtime_hr' => $findCol(['jam lbr', 'jam lembur'], null),
                'overtime_amt' => $findCol(['uang lembur total'], null),
                'overtime_rate' => $findCol(['uang lembur @hari', 'uang lembur @ jam'], null), 
                'loan' => $findCol(['potongan kasbon', 'kasbon'], null), 
                'alfa' => $findCol(['potongan alfa', 'alfa'], null),
                'pot_ewa' => $findCol(['potongan ewa'], null),
                'payroll' => $findCol(['net salary', 'gaji diterima'], null),
                
                // Keep other standard fields just in case
                'incentive' => $findCol(['insentif', 'incentive'], null),
                'incentive_city' => $findCol(['insentif luar kota', 'city incentive'], null),
                'incentive_attend' => $findCol(['insentif kehadiran', 'attendance incentive'], null), 
                'piket' => $findCol(['piket', 'piket um sabtu', 'piket dan um sabtu'], null),
                'adj' => $findCol(['adj', 'adjustment', 'adj gaji'], null),
                'total_gaji' => $findCol(['total gaji', 'gross salary'], null),
                'net_received' => $findCol(['gaji diterima', 'gaji', 'net salary'], null),
                'late' => $findCol(['terlambat', 'late'], null),
                'shortage' => $findCol(['selisih', 'shortage'], null),
                'bank' => $findCol(['adm bank', 'bank fee'], null),
                'bpjs_tk' => $findCol(['bpjs tk', 'bpjs employment', 'bpjs ketenagakerjaan'], null),
                'ewa' => $findCol(['ewa'], null),
                'grand_total' => $findCol(['grand total'], null),
            ];

            Log::info("Payroll Ho Import: Mapped Columns Resolved", ['cols' => $cols]);


            $dataRows = [];
            $startRow = $headerRowIndex + 2; // Skip header + unit row

            for ($row = $startRow; $row <= $highestRow; $row++) {
                $name = $sheet->getCell('B' . $row)->getValue();
                // Check mapped column for name if B is empty
                if (empty($name)) {
                    $nameCol = $findCol('nama karyawan', 'B');
                    $name = $sheet->getCell($nameCol . $row)->getValue();
                }
                
                if (empty($name)) continue;

                // Helper for cell value
                $getCellValue = function($col, $dataRow) use ($sheet) {
                    if (!$col) return 0;
                    $val = $sheet->getCell($col . $dataRow)->getCalculatedValue(); 
                    return is_numeric($val) ? $val : 0;
                };

                // Helper for safe cell access
                $safeGet = function($colKey) use ($cols, $getCellValue, $row) {
                    if (empty($cols[$colKey])) return 0;
                    return $getCellValue($cols[$colKey], $row);
                };

                // Extract Values
                $parsed = [
                    'employee_name' => $name,
                    'period' => date('Y-m'), // Default
                    'account_number' => !empty($cols['account']) ? $sheet->getCell($cols['account'] . $row)->getValue() : '',
                    'basic_salary' => $safeGet('basic'),
                    'days_present' => $safeGet('present'),
                    
                    'transport_allowance' => $safeGet('transport_amt'),
                    'transport_rate' => $safeGet('transport_rate'),
                    
                    'attendance_allowance' => $safeGet('attend_amt'),
                    'attendance_rate' => $safeGet('attend_rate'),
                    
                    'health_allowance' => $safeGet('health'),
                    'position_allowance' => $safeGet('position'),
                    
                    'insentif_luar_kota' => $safeGet('incentive_city'),
                    'insentif_kehadiran' => $safeGet('incentive_attend'),
                    'piket_um_sabtu' => $safeGet('piket'),
                    
                    'overtime_hours' => $safeGet('overtime_hr'),
                    // 'overtime_rate' => $safeGet('overtime_rate'),
                    'overtime_amount' => $safeGet('overtime_amt'),
                    
                    'holiday_allowance' => $safeGet('incentive'),
                    'adjustment' => $safeGet('adj'),
                    
                    'total_gaji' => $safeGet('total_gaji'),
                    'gaji_diterima' => $safeGet('net_received'),
                    
                    'deductions' => [
                        'absent' => $safeGet('absent'),
                        'late' => $safeGet('late'),
                        'alfa' => $safeGet('alfa'),
                        'shortage' => $safeGet('shortage'),
                        'loan' => $safeGet('loan'),
                        'bank_fee' => $safeGet('bank'),
                        'bpjs_tk' => $safeGet('bpjs_tk'),
                    ],
                    'ewa' => $safeGet('ewa'),
                    'pot_ewa' => $safeGet('pot_ewa'),
                    'grand_total' => $safeGet('grand_total'),
                    'net_salary' => $safeGet('payroll'),
                ];

                // Auto-calculate Overtime Amount if missing
                if ($parsed['overtime_amount'] == 0 && $parsed['overtime_hours'] > 0) {
                     $rate = $safeGet('overtime_rate');
                     if ($rate > 0) {
                         $parsed['overtime_amount'] = $parsed['overtime_hours'] * $rate;
                     }
                }
                
                // Final logic for ambiguity
                if ($parsed['deductions']['loan'] == 0) {
                     // Try kasbon column if found separately
                }
                
                // DEBUG LOGGING
                if (count($dataRows) === 0) {
                     Log::info("Mapping Used: " . json_encode($cols));
                     Log::info("Row $row Parsed: " . json_encode($parsed));
                }

                $dataRows[] = $parsed;
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'file_name' => $file->getClientOriginalName(),
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            Log::error('HO Payroll Import Error: ' . $e->getMessage());
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Save imported payroll
     */
    public function saveImport(Request $request)
    {
        $request->validate(['rows' => 'required|array', 'rows.*.employee_name' => 'required|string']);
        
        $saved = 0;
        $errors = [];

        Log::info("HO Payroll Import: Received " . count($request->rows) . " rows");
        if (count($request->rows) > 0) {
             Log::info("Row 1 Raw Deductions: " . json_encode($request->rows[0]['deductions'] ?? 'NULL'));
        }

        foreach ($request->rows as $index => $row) {
            $employee = Employee::whereRaw('LOWER(full_name) = ?', [strtolower($row['employee_name'])])->first();
            if (!$employee) {
                // Try fuzzy/partial match or log error
                $errors[] = "Row " . ($index+1) . ": Employee {$row['employee_name']} not found";
                continue;
            }

            $currentPeriod = $row['period'] ?? date('Y-m');
            
            // Normalize deductions (handle string/JSON input)
            if (isset($row['deductions']) && is_string($row['deductions'])) {
                $row['deductions'] = json_decode($row['deductions'], true) ?? [];
            }
            // Ensure values are numeric for array_sum
            if (isset($row['deductions']) && is_array($row['deductions'])) {
                 $row['deductions'] = array_map(function($v) { 
                     return is_numeric($v) ? (float)$v : 0; 
                 }, $row['deductions']);
            }

            // Calculate final fields
            $allowancesTotal = $row['transport_allowance'] + $row['attendance_allowance'] + 
                               $row['health_allowance'] + $row['position_allowance'] + 
                               $row['insentif_luar_kota'] + $row['insentif_kehadiran'] + 
                               $row['piket_um_sabtu'];
            
            $deductionsTotal = array_sum($row['deductions']);
            
            $gross = $row['total_gaji'] > 0 ? $row['total_gaji'] : 
                     ($row['basic_salary'] + $allowancesTotal + $row['overtime_amount'] + $row['holiday_allowance'] + $row['adjustment']);
            
            $net = $row['net_salary'] > 0 ? $row['net_salary'] : ($gross - $deductionsTotal - $row['ewa']);

            Log::info("Row $index Check: Gross=$gross, DedTotal=$deductionsTotal, Net=$net, RawDed=".json_encode($row['deductions']));

            // Prepare Details JSON
            $details = [
                'account_number' => $row['account_number'],
                'days_present' => $row['days_present'],
                'transport_rate' => $row['transport_rate'],
                'transport_allowance' => $row['transport_allowance'],
                'attendance_rate' => $row['attendance_rate'],
                'attendance_allowance' => $row['attendance_allowance'],
                'health_allowance' => $row['health_allowance'],
                'position_allowance' => $row['position_allowance'],
                'insentif_luar_kota' => $row['insentif_luar_kota'],
                'insentif_kehadiran' => $row['insentif_kehadiran'],
                'piket_um_sabtu' => $row['piket_um_sabtu'],
                'overtime_hours' => $row['overtime_hours'],
                'overtime_amount' => $row['overtime_amount'],
                'holiday_allowance' => $row['holiday_allowance'], // THR/Bonus/Insentif
                'adjustment' => $row['adjustment'],
                'deductions' => is_string($row['deductions']) ? json_decode($row['deductions'], true) : $row['deductions'],
                'ewa' => $row['ewa']
            ];

            Payroll::updateOrCreate(
                ['employee_id' => $employee->id, 'period' => $currentPeriod],
                [
                    'basic_salary' => $row['basic_salary'],
                    'allowances' => $allowancesTotal,
                    'overtime_pay' => $row['overtime_amount'],
                    'gross_salary' => $gross,
                    'total_deductions' => $deductionsTotal,
                    'net_salary' => $net,
                    'details' => $details,
                    'status' => 'draft',
                ]
            );
            $saved++;
        }

        return response()->json([
            'message' => "Successfully saved $saved payroll records",
            'saved' => $saved,
            'errors' => $errors
        ]);
    }

    /**
     * Generate Payslip PDF
     */
    public function generatePayslip($id)
    {
        $payroll = Payroll::with(['employee'])->findOrFail($id);
        
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
            $data['approved_by'] = auth()->id();
        }
        
        $payroll->update($data);
        return response()->json(['message' => 'Status updated', 'payroll' => $payroll]);
    }
}
