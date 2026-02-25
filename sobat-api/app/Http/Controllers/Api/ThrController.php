<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Thr;
use App\Models\Employee;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ThrController extends Controller
{
    public function index(Request $request)
    {
        $query = Thr::with(['employee']);

        // Filter by year
        if ($request->has('year')) {
            $query->where('year', $request->year);
        }

        // Filter by division
        if ($request->has('division')) {
            $query->where('division', $request->division);
        }

        // Automatic scope for non-admin users
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';

        if (!in_array($roleName, ['admin', 'super_admin', 'hr', 'operasional'])) {
            $employeeId = $user->employee ? $user->employee->id : null;

            if ($employeeId) {
                $query->where('employee_id', $employeeId);
            } else {
                return response()->json(['data' => []]);
            }
            
            // Non-admin users can ONLY see approved or paid thrs
            $query->whereIn('status', ['approved', 'paid']);
        }

        $thrs = $query->orderBy('year', 'desc')->get();

        return response()->json([
            'data' => $thrs->map(function ($thr) {
                return [
                    'id' => $thr->id,
                    'employee' => [
                        'employee_code' => $thr->employee->employee_code ?? 'N/A',
                        'full_name' => $thr->employee->full_name ?? 'Unknown',
                    ],
                    'year' => $thr->year,
                    'division' => $thr->division,
                    'amount' => (float) $thr->amount,
                    'nominal' => (float) $thr->amount, // Alias for mobile
                    'tax' => (float) $thr->tax,
                    'net_amount' => (float) $thr->net_amount,
                    'net_nominal' => (float) $thr->net_amount, // Alias for mobile
                    'details' => $thr->details,
                    'status' => $thr->status,
                    'paid_at' => $thr->paid_at,
                ];
            }),
        ]);
    }

    public function show(string $id)
    {
        $thr = Thr::with('employee')->findOrFail($id);
        return response()->json($thr);
    }

    /**
     * Generate THR slip PDF
     */
    public function generateSlip(string $id)
    {
        $thr = Thr::with(['employee', 'employee.organization'])->findOrFail($id);

        // Generate PDF
        $pdf = Pdf::loadView('payroll.thr_slip', [
            'thr' => $thr,
            'employee' => $thr->employee,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $filename = 'Slip_THR_' . $thr->employee->employee_code . '_' . $thr->year . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * Import THR from Excel/CSV file
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        $file = $request->file('file');

        try {
            $reader = \PhpOffice\PhpSpreadsheet\IOFactory::createReaderForFile($file->getRealPath());
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($file->getRealPath());
            $sheet = $spreadsheet->getActiveSheet();
            
            $highestRow = $sheet->getHighestRow();
            $highestColumn = $sheet->getHighestColumn();
            
            // Header detection
            $headerRowIndex = -1;
            for ($row = 1; $row <= min(10, $highestRow); $row++) {
                $rowValues = $sheet->rangeToArray('A' . $row . ':' . $highestColumn . $row, NULL, TRUE, FALSE)[0];
                foreach ($rowValues as $val) {
                    if ($val && stripos($val, 'Nama Karyawan') !== false) {
                        $headerRowIndex = $row;
                        break 2;
                    }
                }
            }
            
            if ($headerRowIndex === -1) {
                return response()->json(['message' => 'Format tidak dikenali. Pastikan ada kolom "Nama Karyawan".'], 422);
            }
            
            // Define mapping (Simplified for THR)
            $columnMapping = [];
            $headerRowValues = $sheet->rangeToArray('A' . $headerRowIndex . ':' . $highestColumn . $headerRowIndex, NULL, TRUE, FALSE)[0];
            $cols = range('A', $highestColumn); // This only works for A-Z
            
            // Better column detection
            $colIndex = 0;
            foreach ($headerRowValues as $headerValue) {
                if (!$headerValue) { $colIndex++; continue; }
                
                $colName = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colIndex + 1);
                
                if (stripos($headerValue, 'Nama Karyawan') !== false) $columnMapping['nama_karyawan'] = $colName;
                if (stripos($headerValue, 'Tahun') !== false) $columnMapping['year'] = $colName;
                if (stripos($headerValue, 'Masa kerja') !== false) $columnMapping['masa_kerja'] = $colName;
                if (stripos($headerValue, 'THR') !== false || stripos($headerValue, 'Jumlah') !== false) $columnMapping['amount'] = $colName;
                if (stripos($headerValue, 'Pajak') !== false || stripos($headerValue, 'PPh') !== false) $columnMapping['tax'] = $colName;
                if (stripos($headerValue, 'Diterima') !== false || stripos($headerValue, 'Net') !== false) $columnMapping['net_amount'] = $colName;
                
                $colIndex++;
            }
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 1;
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $sheet->getCell(($columnMapping['nama_karyawan'] ?? 'B') . $row)->getValue();
                if (empty($employeeName)) continue;
                
                $year = $sheet->getCell(($columnMapping['year'] ?? 'A') . $row)->getValue() ?? $request->year ?? date('Y');
                $masaKerja = $columnMapping['masa_kerja'] ?? null ? $sheet->getCell($columnMapping['masa_kerja'] . $row)->getValue() : null;
                $amount = (float) $sheet->getCell(($columnMapping['amount'] ?? 'C') . $row)->getCalculatedValue();
                $tax = (float) $sheet->getCell(($columnMapping['tax'] ?? 'D') . $row)->getCalculatedValue();
                $netAmount = (float) $sheet->getCell(($columnMapping['net_amount'] ?? 'E') . $row)->getCalculatedValue();

                if ($netAmount == 0 && $amount > 0) {
                    $netAmount = $amount - $tax;
                }
                
                $dataRows[] = [
                    'employee_name' => $employeeName,
                    'year' => (string) $year,
                    'amount' => $amount,
                    'tax' => $tax,
                    'net_amount' => $netAmount,
                    'details' => [
                        'masa_kerja' => $masaKerja
                    ],
                ];
            }

            return response()->json([
                'message' => 'File parsed successfully',
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Save imported THR data
     */
    public function saveImport(Request $request)
    {
        $request->validate([
            'rows' => 'required|array',
            'division' => 'nullable|string',
            'rows.*.employee_name' => 'required|string',
            'rows.*.year' => 'required|string',
            'rows.*.amount' => 'required|numeric',
            'rows.*.net_amount' => 'required|numeric',
        ]);

        $rows = $request->input('rows');
        $division = $request->input('division');
        $saved = [];
        $failed = [];

        foreach ($rows as $index => $row) {
            try {
                $employee = Employee::whereRaw('LOWER(full_name) = ?', [strtolower($row['employee_name'])])->first();

                if (!$employee) {
                    $failed[] = [
                        'row' => $index + 1,
                        'employee_name' => $row['employee_name'],
                        'reason' => 'Employee not found',
                    ];
                    continue;
                }

                $thr = Thr::updateOrCreate(
                    [
                        'employee_id' => $employee->id,
                        'year' => $row['year'],
                    ],
                    [
                        'division' => $division,
                        'amount' => $row['amount'],
                        'tax' => $row['tax'] ?? 0,
                        'net_amount' => $row['net_amount'],
                        'details' => $row['details'] ?? [],
                        'status' => 'draft',
                    ]
                );

                $saved[] = [
                    'row' => $index + 1,
                    'employee_name' => $row['employee_name'],
                    'action' => $thr->wasRecentlyCreated ? 'created' : 'updated',
                ];

            } catch (\Exception $e) {
                $failed[] = [
                    'row' => $index + 1,
                    'employee_name' => $row['employee_name'],
                    'reason' => $e->getMessage(),
                ];
            }
        }

        return response()->json([
            'message' => 'THR data saved successfully',
            'summary' => [
                'total' => count($rows),
                'saved' => count($saved),
                'failed' => count($failed),
            ],
            'saved' => $saved,
            'failed' => $failed,
        ]);
    }
}
