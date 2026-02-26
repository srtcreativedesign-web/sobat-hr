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
                        'join_date' => $thr->employee->join_date?->toDateString(),
                    ],
                    'year' => $thr->year,
                    'division' => $thr->division,
                    'amount' => (float) $thr->amount,
                    'nominal' => (float) $thr->amount, // Alias for mobile
                    'details' => $thr->details,
                    'status' => $thr->status,
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
    public function generateSlip(Request $request, string $id)
    {
        $thr = Thr::with(['employee'])->findOrFail($id);

        // Calculate masa kerja from join_date
        $masaKerja = '-';
        if ($thr->employee->join_date) {
            $joinDate = Carbon::parse($thr->employee->join_date);
            $now = Carbon::now();
            $years = (int) $joinDate->diffInYears($now);
            $months = (int) $joinDate->copy()->addYears($years)->diffInMonths($now);
            if ($years == 0) {
                $masaKerja = $months . ' bulan';
            } elseif ($months == 0) {
                $masaKerja = $years . ' tahun';
            } else {
                $masaKerja = $years . ' tahun ' . $months . ' bulan';
            }
        }

        // Get employee signature: use stored one, or save new one from request
        $employeeSignature = $thr->details['employee_signature'] ?? null;
        $incomingSignature = $request->input('employee_signature');

        if (!$employeeSignature && $incomingSignature) {
            // First time signing — save permanently
            $details = $thr->details ?? [];
            $details['employee_signature'] = $incomingSignature;
            $thr->update(['details' => $details]);
            $employeeSignature = $incomingSignature;
        }

        $pdf = Pdf::loadView('payroll.thr_slip', [
            'thr' => $thr,
            'employee' => $thr->employee,
            'masaKerja' => $masaKerja,
            'employeeSignature' => $employeeSignature,
        ]);

        $pdf->setPaper('a4', 'portrait');

        $filename = 'Slip_THR_' . $thr->employee->employee_code . '_' . $thr->year . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * Import THR from Excel/CSV file
     * Expected format: Nama Karyawan | Tahun | THR
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
            
            // Header detection - look for "Nama Karyawan"
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
            
            // Define mapping
            $columnMapping = [];
            $headerRowValues = $sheet->rangeToArray('A' . $headerRowIndex . ':' . $highestColumn . $headerRowIndex, NULL, TRUE, FALSE)[0];
            
            $colIndex = 0;
            foreach ($headerRowValues as $headerValue) {
                if (!$headerValue) { $colIndex++; continue; }
                
                $colName = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colIndex + 1);
                
                if (stripos($headerValue, 'Nama Karyawan') !== false) $columnMapping['nama_karyawan'] = $colName;
                if (stripos($headerValue, 'Tahun') !== false) $columnMapping['year'] = $colName;
                if (stripos($headerValue, 'THR') !== false || stripos($headerValue, 'Jumlah') !== false) $columnMapping['amount'] = $colName;
                
                $colIndex++;
            }

            Log::info('THR Import - Column mapping:', $columnMapping);
            
            $dataRows = [];
            $startDataRow = $headerRowIndex + 1;
            
            for ($row = $startDataRow; $row <= $highestRow; $row++) {
                $employeeName = $sheet->getCell(($columnMapping['nama_karyawan'] ?? 'A') . $row)->getValue();
                if (empty($employeeName)) continue;
                
                $year = isset($columnMapping['year']) 
                    ? $sheet->getCell($columnMapping['year'] . $row)->getValue() 
                    : ($request->year ?? date('Y'));
                    
                $amount = isset($columnMapping['amount'])
                    ? (float) $sheet->getCell($columnMapping['amount'] . $row)->getCalculatedValue()
                    : 0;

                $dataRows[] = [
                    'employee_name' => $employeeName,
                    'year' => (string) $year,
                    'amount' => $amount,
                ];
            }

            Log::info('THR Import - Parsed rows:', ['count' => count($dataRows), 'sample' => array_slice($dataRows, 0, 3)]);

            return response()->json([
                'message' => 'File parsed successfully',
                'rows_count' => count($dataRows),
                'rows' => $dataRows,
            ]);

        } catch (\Exception $e) {
            Log::error('THR Import Error: ' . $e->getMessage());
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

    /**
     * Approve a single THR
     */
    public function approve(Request $request, string $id)
    {
        $request->validate([
            'signer_name' => 'required|string',
            'signature' => 'required|string',
        ]);

        $thr = Thr::findOrFail($id);

        if ($thr->status === 'approved') {
            return response()->json(['message' => 'THR sudah di-approve'], 422);
        }

        $details = $thr->details ?? [];
        $details['signer_name'] = $request->signer_name;
        $details['signature'] = $request->signature;
        $details['approved_at'] = now()->toDateTimeString();

        $thr->update([
            'status' => 'approved',
            'details' => $details,
        ]);

        return response()->json([
            'message' => 'THR berhasil di-approve',
            'data' => $thr,
        ]);
    }

    /**
     * Bulk approve THR records
     */
    public function bulkApprove(Request $request)
    {
        $request->validate([
            'signer_name' => 'required|string',
            'signature' => 'required|string',
        ]);

        $ids = $request->input('ids', []);
        $signerData = [
            'signer_name' => $request->signer_name,
            'signature' => $request->signature,
            'approved_at' => now()->toDateTimeString(),
        ];

        if (empty($ids)) {
            $query = Thr::where('status', 'draft');
            if ($request->has('year')) {
                $query->where('year', $request->year);
            }
            if ($request->has('division') && $request->division !== 'all') {
                $query->where('division', $request->division);
            }
            $thrs = $query->get();
        } else {
            $thrs = Thr::whereIn('id', $ids)->where('status', 'draft')->get();
        }

        $count = 0;
        foreach ($thrs as $thr) {
            $details = $thr->details ?? [];
            $details = array_merge($details, $signerData);
            $thr->update([
                'status' => 'approved',
                'details' => $details,
            ]);
            $count++;
        }

        return response()->json([
            'message' => "{$count} THR berhasil di-approve",
            'approved_count' => $count,
        ]);
    }
}
