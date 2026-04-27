<?php

namespace App\Services;

use App\Models\Payroll;
use App\Models\Employee;
use PhpOffice\PhpSpreadsheet\IOFactory;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PayrollImportService
{
    protected $coreKeywords = [
        'employee_name' => ['nama karyawan', 'nama pegawai', 'employee name', 'nama'],
        'account'       => ['no rekening', 'account number', 'rekening', 'nomor rekening'],
        'basic_salary'  => ['gaji pokok', 'basic salary', 'gapok'],
        'net_salary'    => ['grand total', 'thp', 'total gaji ditransfer', 'gaji diterima', 'net salary'],
        'gross_salary'  => ['total gaji', 'gross salary', 'total gaji & bonus'],
    ];

    public function import($filePath, $period, $type = 'fnb', $outletName = null)
    {
        $spreadsheet = IOFactory::load($filePath);
        $sheet = $spreadsheet->getActiveSheet();
        $rows = $sheet->toArray();

        // 1. Find Header Row
        $headerIndex = $this->findHeaderRow($rows);
        if ($headerIndex === -1) {
            throw new \Exception("Format Excel tidak dikenali: Kolom 'Nama' tidak ditemukan.");
        }

        $headers = $rows[$headerIndex];
        $mapping = $this->mapHeaders($headers);
        
        $results = [
            'success' => 0,
            'failed' => 0,
            'errors' => []
        ];

        // 2. Parse Data Rows
        for ($i = $headerIndex + 1; $i < count($rows); $i++) {
            $rowData = $rows[$i];
            
            // Skip empty rows (check if name is empty)
            $nameIdx = $mapping['core']['employee_name'] ?? -1;
            if ($nameIdx === -1 || empty($rowData[$nameIdx])) continue;

            try {
                DB::transaction(function () use ($rowData, $mapping, $period, $type, $outletName, &$results) {
                    $employee = $this->findEmployee($rowData, $mapping);
                    
                    if (!$employee) {
                        throw new \Exception("Karyawan tidak ditemukan: " . $rowData[$mapping['core']['employee_name']]);
                    }

                    // Extract Core Data
                    $payrollData = [
                        'employee_id' => $employee->id,
                        'period'      => $period,
                        'type'        => $type,
                        'outlet_name' => $outletName,
                        'status'      => 'draft',
                    ];

                    // Map Core Columns
                    foreach ($mapping['core'] as $key => $colIdx) {
                        if ($key === 'employee_name' || $key === 'account') continue;
                        $payrollData[$key] = $this->parseMoney($rowData[$colIdx]);
                    }

                    // Extract Flexible Details (JSON)
                    $details = [];
                    foreach ($mapping['extra'] as $label => $colIdx) {
                        $val = $rowData[$colIdx];
                        if ($val !== null && $val !== '' && $val != 0) {
                            $details[$label] = $this->parseMoney($val);
                        }
                    }
                    $payrollData['details'] = $details;

                    // Manual Calculation of Gross/Net if missing but components exist? 
                    // For now, trust Excel values.

                    Payroll::updateOrCreate(
                        ['employee_id' => $employee->id, 'period' => $period],
                        $payrollData
                    );

                    $results['success']++;
                });
            } catch (\Exception $e) {
                $results['failed']++;
                $results['errors'][] = $e->getMessage();
            }
        }

        return $results;
    }

    private function findHeaderRow($rows)
    {
        foreach ($rows as $index => $row) {
            foreach ($row as $cell) {
                $cell = strtolower(trim($cell));
                if (in_array($cell, $this->coreKeywords['employee_name'])) {
                    return $index;
                }
            }
        }
        return -1;
    }

    private function mapHeaders($headers)
    {
        $mapping = ['core' => [], 'extra' => []];
        
        foreach ($headers as $idx => $header) {
            if (empty($header)) continue;
            
            $headerLower = strtolower(trim($header));
            $foundCore = false;

            foreach ($this->coreKeywords as $key => $patterns) {
                if (in_array($headerLower, $patterns)) {
                    $mapping['core'][$key] = $idx;
                    $foundCore = true;
                    break;
                }
            }

            // If not a core column, put in extra
            if (!$foundCore) {
                // Skip generic headers like "No", "Hari", etc.
                if (in_array($headerLower, ['no', 'hari', 'off', 'sakit', 'ijin', 'alfa', 'cuti', 'ada', 'jumlah'])) {
                    continue;
                }
                $mapping['extra'][$header] = $idx;
            }
        }

        return $mapping;
    }

    private function findEmployee($rowData, $mapping)
    {
        $name = trim($rowData[$mapping['core']['employee_name']] ?? '');
        $account = trim($rowData[$mapping['core']['account']] ?? '');

        // Search by account first (more unique)
        if (!empty($account)) {
            $emp = Employee::where('bank_account_number', $account)->first();
            if ($emp) return $emp;
        }

        // Search by name
        return Employee::where('full_name', 'like', "%$name%")->first();
    }

    private function parseMoney($val)
    {
        if (is_numeric($val)) return (float) $val;
        
        // Remove currency symbols, dots (thousands), and commas (decimal)
        $clean = preg_replace('/[^\d,]/', '', $val);
        $clean = str_replace(',', '.', $clean);
        
        return (float) $clean;
    }
}
