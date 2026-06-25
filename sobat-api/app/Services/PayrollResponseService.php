<?php

namespace App\Services;

class PayrollResponseService
{
    /**
     * Format a standard Payroll model (HO)
     */
    public function formatStandardPayroll($payroll)
    {
        // Accept either Model or Array
        $record = is_array($payroll) ? (object) $payroll : $payroll;
        $details = is_array($payroll) ? ($payroll['details'] ?? []) : ($record->details ?? []);
        
        $periodDate = $record->period . '-01';
        $periodStart = date('Y-m-01', strtotime($periodDate));
        $periodEnd = date('Y-m-t', strtotime($periodDate));

        $data = [
            'id' => $record->id,
            'employee' => [
                'employee_code' => $record->employee->employee_code ?? 'N/A',
                'full_name' => $record->employee->full_name ?? 'Unknown',
            ],
            'period' => $record->period,
            'period_start' => $periodStart,
            'period_end' => $periodEnd,
            'basic_salary' => round((float) ($record->basic_salary ?? 0), 0),
            'allowances' => round((float) ($record->allowances ?? 0), 0),
            'overtime_pay' => round((float) ($record->overtime_pay ?? 0), 0),
            'deductions' => round((float) ($record->total_deductions ?? 0), 0),
            'bpjs_health' => round((float) ($record->bpjs_kesehatan ?? 0), 0),
            'bpjs_employment' => round((float) ($record->bpjs_ketenagakerjaan ?? 0), 0),
            'tax' => round((float) ($record->pph21 ?? 0), 0),
            'gross_salary' => round((float) ($record->gross_salary ?? 0), 0),
            'net_salary' => round((float) ($record->net_salary ?? 0), 0),
            'details' => $details,
            'status' => $record->status === 'draft' ? 'pending' : $record->status,
        ];
        
        if (isset($details['days_present'])) {
            $data['attendance'] = [
                'Hadir' => $details['days_present'] ?? 0,
                'Sakit' => $details['days_sick'] ?? 0,
                'Ijin' => $details['days_permission'] ?? 0,
                'Alfa' => $details['days_alpha'] ?? 0,
                'Cuti' => $details['days_leave'] ?? 0,
            ];
        }
        
        $allowancesMap = [];
        $daysPresent = $details['days_present'] ?? 0;
        $formatRate = function ($amount, $defaultLabel) use ($daysPresent) {
            if ($daysPresent > 0 && $amount > 0 && fmod($amount, $daysPresent) == 0) {
                $rate = $amount / $daysPresent;
                if ($rate >= 1000) return $defaultLabel . ' (Rp ' . number_format($rate, 0, ',', '.') . ' /hari)';
            }
            return $defaultLabel;
        };

        if (($details['transport_allowance'] ?? 0) > 0) $allowancesMap[$formatRate($details['transport_allowance'], 'Transport')] = $details['transport_allowance'];
        if (($details['health_allowance'] ?? 0) > 0) $allowancesMap['Tunjangan Kesehatan'] = $details['health_allowance'];
        if (($details['position_allowance'] ?? 0) > 0) $allowancesMap['Tunjangan Jabatan'] = $details['position_allowance'];
        if (($details['holiday_allowance'] ?? 0) > 0) $allowancesMap['Tunjangan Hari Raya'] = $details['holiday_allowance'];
        if (($details['attendance_allowance'] ?? 0) > 0) $allowancesMap[$formatRate($details['attendance_allowance'], 'Kehadiran')] = $details['attendance_allowance'];
        if (($details['meal_allowance'] ?? 0) > 0) $allowancesMap[$formatRate($details['meal_allowance'], 'Uang Makan')] = $details['meal_allowance'];
        if (($details['bonus'] ?? 0) > 0) $allowancesMap['Bonus / THR'] = $details['bonus'];
        if (($details['target_koli'] ?? 0) > 0) $allowancesMap['Target Koli'] = $details['target_koli'];
        if (($details['accessory_fee'] ?? 0) > 0) $allowancesMap['Accessory Fee'] = $details['accessory_fee'];
        if (($details['backup'] ?? 0) > 0) $allowancesMap['Backup'] = $details['backup'];
        if (($details['policy_ho'] ?? 0) > 0) $allowancesMap['Kebijakan HO'] = $details['policy_ho'];
        if (($details['adjustment'] ?? 0) > 0) $allowancesMap['Adjustment'] = $details['adjustment'];
        if (($details['insentif_kehadiran'] ?? 0) > 0) $allowancesMap['Insentif Kehadiran'] = $details['insentif_kehadiran'];
        
        if (($details['overtime_hours'] ?? 0) > 0) {
            $allowancesMap['Lembur'] = [
                'amount' => $record->overtime_pay ?? 0,
                'hours' => $details['overtime_hours'],
            ];
        }
        if (!empty($allowancesMap)) $data['allowances'] = $allowancesMap;

        $deductionsMap = [];
        $d = $details['deductions'] ?? [];
        if (($d['absent'] ?? 0) > 0) $deductionsMap['Absen'] = $d['absent'];
        if (($d['alfa'] ?? 0) > 0) $deductionsMap['Alfa'] = $d['alfa'];
        if (($d['late'] ?? 0) > 0) $deductionsMap['Terlambat'] = $d['late'];
        if (($d['shortage'] ?? 0) > 0) $deductionsMap['Selisih SO'] = $d['shortage'];
        if (($d['loan'] ?? 0) > 0) $deductionsMap['Pinjaman/Kasbon'] = $d['loan'];
        if (($d['bank_fee'] ?? 0) > 0) $deductionsMap['Biaya Admin Bank'] = $d['bank_fee'];
        if (($d['bpjs_tk'] ?? 0) > 0) $deductionsMap['BPJS Ketenagakerjaan'] = $d['bpjs_tk'];
        if (!empty($deductionsMap)) $data['deductions'] = $deductionsMap;
        
        if (isset($d['ewa']) && $d['ewa'] > 0) {
             $data['ewa_amount'] = $d['ewa'];
        }

        return $data;
    }

    /**
     * Format an alternative Retail-like Payroll model (FnB, Cellular, etc)
     */
    public function formatRetailPayroll($record)
    {
        $periodDate = $record->period . '-01';
        $periodStart = date('Y-m-01', strtotime($periodDate));
        $periodEnd = date('Y-m-t', strtotime($periodDate));

        $data = [
            'id' => $record->id,
            'employee' => [
                'employee_code' => $record->employee->employee_code ?? 'N/A',
                'full_name' => $record->employee->full_name ?? 'Unknown',
            ],
            'period' => $record->period,
            'period_start' => $periodStart,
            'period_end' => $periodEnd,
            'status' => $record->status === 'draft' ? 'pending' : $record->status,
        ];

        $data['basic_salary'] = round((float) ($record->basic_salary ?? 0), 0);
        $data['allowances'] = 0; // Summarized in map below
        $data['overtime_pay'] = round((float) ($record->overtime_amount ?? 0), 0);
        $data['deductions'] = round((float) ($record->total_deductions ?? $record->deduction_total ?? 0), 0);
        $data['bpjs_health'] = 0;
        $data['bpjs_employment'] = round((float) ($record->deduction_bpjs_tk ?? 0), 0);
        $data['tax'] = 0;
        $data['gross_salary'] = round((float) ($record->total_salary_2 ?? $record->gross_salary ?? 0), 0);
        $data['net_salary'] = round((float) ($record->net_salary ?? $record->grand_total ?? 0), 0);
        
        if (($record->ewa_amount ?? 0) > 0) {
            $data['ewa_amount'] = $record->ewa_amount;
        }

        $data['attendance'] = [
            'Hadir' => $record->days_present ?? 0,
            'Sakit' => $record->days_sick ?? 0,
            'Ijin' => $record->days_permission ?? 0,
            'Alfa' => $record->days_alpha ?? 0,
            'Cuti' => $record->days_leave ?? 0,
        ];
        
        $allowancesMap = [];
        if (($record->transport_amount ?? 0) > 0) {
            $label = 'Transport';
            if (($record->transport_rate ?? 0) >= 1000) $label .= ' (Rp ' . number_format($record->transport_rate, 0, ',', '.') . ' /hari)';
            $allowancesMap[$label] = $record->transport_amount;
        }
        if (($record->health_allowance ?? 0) > 0) $allowancesMap['Tunjangan Kesehatan'] = $record->health_allowance;
        if (($record->position_allowance ?? 0) > 0) $allowancesMap['Tunjangan Jabatan'] = $record->position_allowance;
        if (($record->holiday_allowance ?? 0) > 0) $allowancesMap['Tunjangan Hari Raya'] = $record->holiday_allowance;
        
        $attAmt = $record->attendance_amount ?? $record->attendance_allowance ?? 0;
        if ($attAmt > 0) {
            $label = 'Kehadiran';
            if (($record->attendance_rate ?? 0) >= 1000) $label .= ' (Rp ' . number_format($record->attendance_rate, 0, ',', '.') . ' /hari)';
            $allowancesMap[$label] = $attAmt;
        }
        if (($record->meal_amount ?? 0) > 0) {
            $label = 'Uang Makan';
            if (($record->meal_rate ?? 0) >= 1000) $label .= ' (Rp ' . number_format($record->meal_rate, 0, ',', '.') . ' /hari)';
            $allowancesMap[$label] = $record->meal_amount;
        }
        if (($record->bonus ?? 0) > 0) $allowancesMap['Bonus / THR'] = $record->bonus;
        if (($record->target_koli ?? 0) > 0) $allowancesMap['Target Koli'] = $record->target_koli;
        if (($record->accessory_fee ?? 0) > 0) $allowancesMap['Accessory Fee'] = $record->accessory_fee;
        if (($record->backup ?? 0) > 0) $allowancesMap['Backup'] = $record->backup;
        if (($record->policy_ho ?? 0) > 0) $allowancesMap['Kebijakan HO'] = $record->policy_ho;
        if (($record->adjustment ?? 0) > 0) $allowancesMap['Adjustment'] = $record->adjustment;
        if (($record->insentif_kehadiran ?? 0) > 0) $allowancesMap['Insentif Kehadiran'] = $record->insentif_kehadiran;
        
        if (($record->overtime_hours ?? 0) > 0) {
            $allowancesMap['Lembur'] = [
                'amount' => $record->overtime_amount ?? 0,
                'hours' => $record->overtime_hours,
            ];
        }
        if (!empty($allowancesMap)) $data['allowances'] = $allowancesMap;

        $deductionsMap = [];
        if (($record->deduction_absent ?? 0) > 0) $deductionsMap['Potongan Absen'] = $record->deduction_absent;
        if (($record->deduction_late ?? 0) > 0) $deductionsMap['Terlambat'] = $record->deduction_late;
        $shortage = $record->deduction_shortage ?? $record->deduction_so_shortage ?? 0;
        if ($shortage > 0) $deductionsMap['Selisih SO'] = $shortage;
        if (($record->deduction_loan ?? 0) > 0) $deductionsMap['Pinjaman/Kasbon'] = $record->deduction_loan;
        if (($record->deduction_admin_fee ?? 0) > 0) $deductionsMap['Biaya Admin Bank'] = $record->deduction_admin_fee;
        if (($record->deduction_bpjs_tk ?? 0) > 0) $deductionsMap['BPJS Ketenagakerjaan'] = $record->deduction_bpjs_tk;
        if (!empty($deductionsMap)) $data['deductions'] = $deductionsMap;

        return $data;
    }
}
