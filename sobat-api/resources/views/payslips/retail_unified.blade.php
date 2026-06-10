<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Slip Gaji</title>
    <style>
        @page {
            margin: 10px 20px;
        }
        body {
            font-family: Arial, sans-serif;
            font-size: 10px;
            color: #333;
            line-height: 1.2;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #1a5276;
            padding-bottom: 5px;
        }
        .company-name {
            font-size: 16px;
            font-weight: bold;
            color: #1a5276;
            text-transform: uppercase;
        }
        .division-name {
            font-size: 12px;
            color: #2e86c1;
            font-weight: bold;
        }
        .period {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .info-table {
            width: 100%;
            margin-bottom: 20px;
        }
        .info-label {
            width: 120px;
            font-weight: bold;
        }
        .section-title {
            background-color: #d6eaf8;
            color: #1a5276;
            padding: 4px 8px;
            font-weight: bold;
            margin-top: 10px;
            margin-bottom: 5px;
            border-left: 4px solid #1a5276;
            font-size: 10px;
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
        }
        .details-table td {
            padding: 2px 0;
        }
        .amount {
            text-align: right;
            font-family: 'Courier New', monospace;
        }
        .subtotal {
            border-top: 1px solid #ddd;
            font-weight: bold;
            padding-top: 5px;
        }
        .total-section {
            background-color: #1a5276;
            color: white;
            padding: 10px;
            margin-top: 20px;
            border-radius: 4px;
        }
        .attendance-box {
            border: 1px solid #ddd;
            padding: 10px;
            margin-bottom: 20px;
            background-color: #f9f9f9;
        }
        .attendance-item {
            display: inline-block;
            margin-right: 15px;
            font-size: 10px;
        }
        .signature-section {
            margin-top: 20px;
            width: 100%;
            page-break-inside: avoid;
        }
        .signature-box {
            width: 40%;
            float: right;
            text-align: center;
        }
        .signature-line {
            border-bottom: 1px solid #333;
            margin-top: 60px;
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
    @php
        $divisionMap = [
            'money_changer' => 'MONEY CHANGER',
            'minimarket' => 'MINIMARKET',
            'reflexiology' => 'REFLEXIOLOGY',
            'wrapping' => 'WRAPPING',
            'hans' => 'SECURITY (HANS)',
            'cellular' => 'CELLULLER',
            'office' => 'HEAD OFFICE'
        ];
        $displayDivision = $divisionMap[$payroll->division_type ?? ''] ?? strtoupper(str_replace('_', ' ', $payroll->division_type ?? 'RETAIL'));
        
        $slipPrefixMap = [
            'money_changer' => 'MC',
            'minimarket' => 'MM',
            'reflexiology' => 'REF',
            'wrapping' => 'WRAP',
            'hans' => 'HANS',
            'cellular' => 'CELL',
        ];
        $slipPrefix = $slipPrefixMap[$payroll->division_type ?? ''] ?? 'RET';
    @endphp

    <div class="header">
        <div class="company-name">SRT Corporation</div>
        <div class="division-name">{{ $displayDivision }}</div>
        <div class="period">PERIODE: {{ strtoupper(\Carbon\Carbon::parse($payroll->period . '-01')->translatedFormat('F Y')) }}</div>
    </div>

    <table class="info-table">
        <tr>
            <td class="info-label">Nama</td>
            <td>: {{ strtoupper($payroll->employee->full_name) }}</td>
            <td class="info-label" style="text-align: right;">No. Slip</td>
            <td style="width: 120px; text-align: right;">: SAL-{{ $slipPrefix }}-{{ $payroll->id }}</td>
        </tr>
        <tr>
            <td class="info-label">Divisi</td>
            <td>: {{ $displayDivision }}</td>
            <td class="info-label" style="text-align: right;"></td>
            <td style="text-align: right;"></td>
        </tr>
        <tr>
            <td class="info-label">No. Rekening</td>
            <td>: {{ $payroll->account_number ?? '-' }}</td>
        </tr>
    </table>

    <div class="attendance-box">
        <div style="font-weight: bold; margin-bottom: 5px;">DATA KEHADIRAN:</div>
        @if(isset($payroll->attendance) && is_array($payroll->attendance))
            @foreach($payroll->attendance as $key => $val)
                @if($val > 0 || $key === 'Hadir' || $key === 'Total Hari')
                    <span class="attendance-item">{{ $key }}: @if($key === 'Hadir')<b>{{ $val }}</b>@else{{ $val }}@endif</span>
                @endif
            @endforeach
        @else
            <span class="attendance-item">Total Hari: {{ $payroll->days_total }}</span>
            <span class="attendance-item">Hadir: <b>{{ $payroll->days_present }}</b></span>
            @if($payroll->days_long_shift > 0)<span class="attendance-item">Long Shift: {{ $payroll->days_long_shift }}</span>@endif
            <span class="attendance-item">Off: {{ $payroll->days_off }}</span>
            <span class="attendance-item">Sakit: {{ $payroll->days_sick }}</span>
            <span class="attendance-item">Ijin: {{ $payroll->days_permission }}</span>
            <span class="attendance-item">Alfa: {{ $payroll->days_alpha }}</span>
            <span class="attendance-item">Cuti: {{ $payroll->days_leave }}</span>
        @endif
    </div>

    @if($payroll->years_of_service)
    <div style="margin-bottom: 10px; font-style: italic;">
        Masa Kerja: {{ $payroll->years_of_service }}
    </div>
    @endif

    <div class="section-title">PENDAPATAN (INCOME)</div>
    <table class="details-table">
        <tr>
            <td>Gaji Pokok</td>
            <td class="amount">Rp {{ number_format($payroll->basic_salary, 0, ',', '.') }}</td>
        </tr>
        
        @if(isset($payroll->allowances) && is_array($payroll->allowances))
            @foreach($payroll->allowances as $key => $value)
                @php
                    $amt = is_array($value) ? ($value['amount'] ?? 0) : $value;
                @endphp
                
                @if($amt > 0)
                    <tr>
                        <td>
                            {{ $key }}
                            @if(is_array($value))
                                @if(isset($value['rate']) && $value['rate'] > 0)
                                    @if($key === 'Lembur')
                                        (Rp {{ number_format($value['rate'], 0, ',', '.') }} /jam)
                                    @else
                                        ({{ number_format($value['rate'], 0) }} x {{ $payroll->days_present }})
                                    @endif
                                @endif
                                @if(isset($value['hours']) && $value['hours'] > 0)
                                    ({{ number_format($value['hours'], 0) }} Jam)
                                @endif
                            @endif
                        </td>
                        <td class="amount">Rp {{ number_format($amt, 0, ',', '.') }}</td>
                    </tr>
                @endif
            @endforeach
        @endif
        
         <tr style="height: 10px;"></tr>
         <tr>
            <td style="font-weight: bold;">TOTAL PENDAPATAN KOTOR</td>
            <td class="amount" style="font-weight: bold;">Rp {{ number_format($payroll->total_salary_2 > 0 ? $payroll->total_salary_2 : ($payroll->net_salary + ($payroll->deduction_total ?? 0)), 0, ',', '.') }}</td>
        </tr>
    </table>

    <div class="section-title">POTONGAN (DEDUCTIONS)</div>
    <table class="details-table">
        @php
            $totalDeductions = 0;
        @endphp
        
        @if(isset($payroll->deductions) && is_array($payroll->deductions))
            @foreach($payroll->deductions as $key => $amt)
                @if($amt > 0)
                    @php $totalDeductions += $amt; @endphp
                    <tr>
                        <td>
                            {{ $key }}
                            @if($key === 'Potongan Absen')
                                (Absen 1X)
                            @endif
                        </td>
                        <td class="amount">Rp {{ number_format($amt, 0, ',', '.') }}</td>
                    </tr>
                @endif
            @endforeach
        @endif
        
        <tr style="height: 5px;"></tr>
        <tr>
            <td style="font-weight: bold; color: #d32f2f;">TOTAL POTONGAN</td>
            <td class="amount" style="font-weight: bold; color: #d32f2f;">(Rp {{ number_format($totalDeductions, 0, ',', '.') }})</td>
        </tr>
    </table>
    
    @if($payroll->notes)
    <div style="margin-top: 20px; border: 1px dashed #ccc; padding: 10px; font-style: italic; background-color: #fffde7;">
        <strong>Catatan (Ket):</strong> {{ $payroll->notes }}
    </div>
    @endif

    <div class="total-section">
        <table style="width: 100%;">
            <tr>
                <td style="font-size: 12px; font-weight: bold; color: #333;">TOTAL PENDAPATAN (THP)</td>
                <td style="font-size: 14px; font-weight: bold; text-align: right;">Rp {{ number_format($payroll->thp ?? $payroll->net_salary, 0, ',', '.') }}</td>
            </tr>
            @if(isset($payroll->ewa_amount) && $payroll->ewa_amount > 0)
            <tr>
                <td style="font-size: 12px; font-weight: bold; color: #d32f2f;">POTONGAN STAFBOOK (EWA)</td>
                <td style="font-size: 14px; font-weight: bold; color: #d32f2f; text-align: right;">-Rp {{ number_format($payroll->ewa_amount, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr>
                <td style="font-size: 14px; font-weight: bold; padding-top: 5px;">TOTAL DITRANSFER</td>
                <td style="font-size: 16px; font-weight: bold; text-align: right; padding-top: 5px;">Rp {{ number_format(isset($payroll->final_payment) ? $payroll->final_payment : $payroll->net_salary, 0, ',', '.') }}</td>
            </tr>
        </table>
    </div>
    
    <!-- AI Generated Message -->
    @if(!empty($aiMessage))
        <div style="margin-top: 15px; background-color: #f0fdf4; border: 1px solid #1A4D2E; border-radius: 6px; padding: 10px;">
            <strong style="display: block; margin-bottom: 8px; color: #1e40af; font-size: 11px;">📌 Pesan Personal untuk Anda:</strong>
            <div style="font-style: italic; color: #374151;">"{{ $aiMessage }}"</div>
        </div>
    @endif
    
    <div class="signature-section">
        <div class="signature-box">
            <div>Disetujui Oleh,</div>
            @if($payroll->approval_signature)
                <img src="{{ $payroll->approval_signature }}" style="height: 50px; margin-top: 5px;">
                <div style="border-bottom: 1px solid #333; margin-bottom: 5px;"></div>
            @else
                <div class="signature-line"></div>
            @endif
            <div style="font-weight: bold;">{{ $payroll->signer_name ?? 'HR Department' }}</div>
        </div>
    </div>
</body>
</html>
