```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Slip Gaji - {{ $payroll->employee->full_name }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
        @page {
            margin: 5mm 10mm;
        }
        body {
            font-family: 'Arial', sans-serif;
            font-size: 9px;
            color: #333;
            padding: 0;
            line-height: 1.2;
        }
        .header {
            text-align: center;
            margin-bottom: 10px;
            border-bottom: 2px solid #2D1B22;
            padding-bottom: 5px;
        }
        /* ... */
        
        .section {
            margin: 10px 0;
            page-break-inside: avoid;
        }
        
        /* Compact tables */
        td, th {
            padding: 3px 6px !important;
            font-size: 9px;
        }
        .section-title {
            font-size: 14px;
            font-weight: bold;
            color: #2D1B22;
            margin-bottom: 10px;
            padding-bottom: 5px;
            border-bottom: 2px solid #2D1B22;
        }
        
        /* Attendance Table */
        .attendance-table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        .attendance-table td {
            width: 14.28%; /* 7 items equal width */
            text-align: center;
            padding: 10px;
            background: #e8f4f8;
            border: 2px solid #fff;
        }
        .attendance-value {
            font-size: 16px;
            font-weight: bold;
            color: #2D1B22;
            display: block;
        }
        .attendance-label {
            font-size: 10px;
            color: #666;
            display: block;
            margin-top: 5px;
        }
        
        /* Salary Table */
        .salary-table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        .salary-table th {
            background: #2D1B22;
            color: white;
            padding: 10px;
            text-align: left;
            font-weight: bold;
        }
        .salary-table td {
            padding: 8px 10px;
            border-bottom: 1px solid #e0e0e0;
        }
        .amount-column {
            text-align: right;
            font-weight: 600;
        }
        .positive { color: #28a745; }
        .negative { color: #dc3545; }
        .subtotal-row td {
            background: #f8f9fa;
            font-weight: bold;
            border-top: 2px solid #e0e0e0;
        }
        .total-row td {
            background: #2D1B22;
            color: white;
            font-size: 14px;
            font-weight: bold;
            padding: 12px 10px;
        }
        
        .ewa-section {
            background: #fff5f5;
            border: 2px solid #dc3545;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
        }
        .ewa-table { width: 100%; }
        .ewa-title {
            font-weight: bold;
            color: #dc3545;
        }
        .ewa-amount {
            font-size: 18px;
            font-weight: bold;
            color: #dc3545;
            text-align: right;
        }
        
        /* Signature Section - Using Table for consistent layout */
        .signature-table {
            width: 100%;
            margin-top: 40px;
        }
        .signature-table td {
            width: 50%;
            text-align: center;
            vertical-align: top;
        }
        .signature-line {
            margin-top: 60px;
            border-top: 1px solid #333;
            width: 80%;
            margin-left: auto;
            margin-right: auto;
            padding-top: 5px;
        }
        
        .footer {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 2px solid #e0e0e0;
            font-size: 10px;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">SOBAT HR - Food & Beverage Division</div>
        <div class="slip-title">SLIP GAJI KARYAWAN</div>
        <div style="margin-top: 10px; font-size: 12px; color: #666;">
            Periode: {{ date('F Y', strtotime($payroll->period . '-01')) }}
        </div>
    </div>

    <div class="employee-info">
        <table class="info-table">
            <tr>
                <td class="info-label" style="width: 15%;">Nama:</td>
                <td class="info-value" style="width: 35%;">{{ $payroll->employee->full_name }}</td>
                <td class="info-label" style="width: 15%;">Jabatan:</td>
                <td class="info-value" style="width: 35%;">{{ $payroll->employee->position ?? $payroll->jabatan ?? '-' }}</td>
            </tr>
            <tr>
                <td class="info-label">NIK:</td>
                <td class="info-value">{{ $payroll->employee->nik ?? $payroll->employee->employee_code }}</td>
                <td class="info-label">Divisi:</td>
                <td class="info-value">{{ $payroll->employee->department ?? 'Food & Beverage' }}</td>
            </tr>
            <tr>
                <td class="info-label">Join Date:</td>
                <td class="info-value">{{ $payroll->employee->join_date ? \Carbon\Carbon::parse($payroll->employee->join_date)->format('d M Y') : '-' }}</td>
                <td class="info-label">Lokasi:</td>
                <td class="info-value">{{ $payroll->lokasi ?? '-' }}</td>
            </tr>
        </table>
    </div>

    @if($payroll->attendance)
    <div class="section">
        <div class="section-title">DATA KEHADIRAN</div>
        <table class="attendance-table">
            <tr>
            @foreach($payroll->attendance as $type => $count)
                <td>
                    <span class="attendance-value">{{ $count }}</span>
                    <span class="attendance-label">{{ $type }}</span>
                </td>
            @endforeach
            </tr>
        </table>
    </div>
    @endif

    <div class="section">
        <div class="section-title">RINCIAN PENGHASILAN</div>
        <table class="salary-table">
            <thead>
                <tr>
                    <th>Keterangan</th>
                    <th class="amount-column">Jumlah (Rp)</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Gaji Pokok</td>
                    <td class="amount-column">{{ number_format($payroll->basic_salary, 0, ',', '.') }}</td>
                </tr>
                
                @if($payroll->allowances)
                    @foreach($payroll->allowances as $name => $value)
                        @php
                            $amount = is_array($value) && isset($value['amount']) ? $value['amount'] : $value;
                        @endphp
                        @if($amount > 0)
                        <tr>
                            <td class="positive">
                                + {{ $name }}
                                @if(is_array($value) && isset($value['hours']) && $value['hours'] > 0)
                                    ({{ $value['hours'] }} Jam)
                                @endif
                            </td>
                            <td class="amount-column positive">{{ number_format($amount, 0, ',', '.') }}</td>
                        </tr>
                        @endif
                    @endforeach
                @endif
                
                <tr class="subtotal-row">
                    <td>TOTAL PENGHASILAN BRUTO</td>
                    <td class="amount-column">{{ number_format($payroll->total_salary_2, 0, ',', '.') }}</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="section">
        <div class="section-title">POTONGAN</div>
        <table class="salary-table">
            <thead>
                <tr>
                    <th>Keterangan</th>
                    <th class="amount-column">Jumlah (Rp)</th>
                </tr>
            </thead>
            <tbody>
                @if($payroll->deductions)
                    @foreach($payroll->deductions as $name => $amount)
                        @if($amount > 0)
                        <tr>
                            <td class="negative">- {{ $name }}</td>
                            <td class="amount-column negative">{{ number_format($amount, 0, ',', '.') }}</td>
                        </tr>
                        @endif
                    @endforeach
                @endif
                
                @if($payroll->ewa_amount > 0)
                <tr>
                    <td class="negative">- EWA (KASBON)</td>
                    <td class="amount-column negative">{{ number_format($payroll->ewa_amount, 0, ',', '.') }}</td>
                </tr>
                @endif
                
                <tr class="subtotal-row">
                    <td>TOTAL POTONGAN</td>
                    <td class="amount-column">{{ number_format($payroll->total_deductions + $payroll->ewa_amount, 0, ',', '.') }}</td>
                </tr>
            </tbody>
        </table>
    </div>

    {{-- EWA Section Removed (Merged into Deductions) --}}

    <table class="salary-table">
        <tr class="total-row">
            <td>TOTAL GAJI YANG DITERIMA (TAKE HOME PAY)</td>
            <td class="amount-column">Rp {{ number_format($payroll->net_salary, 0, ',', '.') }}</td>
        </tr>
    </table>

    <table class="signature-table">
        <tr>
            <td>
                <div>Diterima Oleh,</div>
                <div style="margin-top: 60px; border-bottom: 1px solid #333; width: 60%; margin-left: auto; margin-right: auto;"></div>
                <div style="margin-top: 5px;">{{ $payroll->employee->full_name }}</div>
            </td>
            <td>
                <div>Mengetahui,</div>
                @if($payroll->approval_signature)
                    <div style="margin-top: 10px; margin-bottom: 5px;">
                        <img src="{{ $payroll->approval_signature }}" alt="Signature" style="height: 60px; max-width: 150px;">
                    </div>
                @else
                    <div style="height: 75px;"></div>
                @endif
                <div style="border-bottom: 1px solid #333; width: 60%; margin-left: auto; margin-right: auto;"></div>
                <div style="margin-top: 5px;">{{ $payroll->signer_name ?? 'HRD' }}</div>
            </td>
        </tr>
    </table>

    <div class="footer">
        <p>Dokumen ini dibuat secara otomatis melalui sistem SOBAT HR</p>
        <p>Dicetak pada: {{ date('d F Y H:i:s') }}</p>
    </div>
</body>
</html>
```
