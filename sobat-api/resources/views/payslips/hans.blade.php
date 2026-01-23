<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Slip Gaji Hans</title>
    <style>
        @page {
            margin: 10px 20px;
        }
        body {
            font-family: Arial, sans-serif;
            font-size: 10px; /* Reduced from 11px */
            color: #333;
            line-height: 1.2; /* Reduced from 1.4 */
        }
        .header {
            text-align: center;
            margin-bottom: 20px; /* Reduced */
            border-bottom: 2px solid #5d3a50;
            padding-bottom: 5px; /* Reduced */
        }
        .company-name {
            font-size: 16px;
            font-weight: bold;
            color: #5d3a50;
            text-transform: uppercase;
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
            background-color: #fce4ec;
            color: #5d3a50;
            padding: 4px 8px; /* Reduced */
            font-weight: bold;
            margin-top: 10px; /* Reduced */
            margin-bottom: 5px; /* Reduced */
            border-left: 4px solid #5d3a50;
            font-size: 10px;
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
        }
        .details-table td {
            padding: 2px 0; /* Reduced from 4px */
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
            background-color: #5d3a50;
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
    <div class="header">
        <div class="company-name">SRT Corporation</div>
        <div class="period">PERIODE: {{ strtoupper(\Carbon\Carbon::parse($payroll->period . '-01')->translatedFormat('F Y')) }}</div>
    </div>

    <table class="info-table">
        <tr>
            <td class="info-label">Nama</td>
            <td>: {{ strtoupper($payroll->employee->full_name) }}</td>
            <td class="info-label" style="text-align: right;">No. Slip</td>
            <td style="width: 100px; text-align: right;">: SAL-HANS-{{ $payroll->id }}</td>
        </tr>
        <tr>
            <td class="info-label">Divisi</td>
            <td>: HANS</td>
            <td class="info-label" style="text-align: right;">Tanggal</td>
            <td style="text-align: right;">: {{ date('d/m/Y') }}</td>
        </tr>
        <tr>
            <td class="info-label">No. Rekening</td>
            <td>: {{ $payroll->account_number ?? '-' }}</td>
        </tr>
    </table>

    <div class="attendance-box">
        <div style="font-weight: bold; margin-bottom: 5px;">DATA KEHADIRAN:</div>
        <span class="attendance-item">Total Hari: {{ $payroll->days_total }}</span>
        <span class="attendance-item">Hadir: <b>{{ $payroll->days_present }}</b></span>
        <span class="attendance-item">Off: {{ $payroll->days_off }}</span>
        <span class="attendance-item">Sakit: {{ $payroll->days_sick }}</span>
        <span class="attendance-item">Ijin: {{ $payroll->days_permission }}</span>
        <span class="attendance-item">Alfa: {{ $payroll->days_alpha }}</span>
        <span class="attendance-item">Cuti: {{ $payroll->days_leave }}</span>
        <span class="attendance-item">Long Shift: {{ $payroll->days_long_shift }}</span>
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
        <tr>
            <td>Uang Makan ({{ number_format($payroll->meal_rate, 0) }} x {{ $payroll->days_present }})</td>
            <td class="amount">Rp {{ number_format($payroll->meal_amount, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td>Transport ({{ number_format($payroll->transport_rate, 0) }} x {{ $payroll->days_present }})</td>
            <td class="amount">Rp {{ number_format($payroll->transport_amount, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td>Tunjangan Kehadiran ({{ number_format($payroll->attendance_rate, 0) }} x {{ $payroll->days_present }})</td>
            <td class="amount">Rp {{ number_format($payroll->attendance_amount, 0, ',', '.') }}</td>
        </tr>
        
        @if($payroll->position_allowance > 0)
        <tr>
            <td>Tunjangan Jabatan</td>
            <td class="amount">Rp {{ number_format($payroll->position_allowance, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->health_allowance > 0)
        <tr>
            <td>Tunjangan Kesehatan</td>
            <td class="amount">Rp {{ number_format($payroll->health_allowance, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($payroll->overtime_amount > 0)
        <tr>
            <td>Lembur ({{ $payroll->overtime_hours }} Jam)</td>
            <td class="amount">Rp {{ number_format($payroll->overtime_amount, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->bonus > 0)
        <tr>
            <td>Bonus</td>
            <td class="amount">Rp {{ number_format($payroll->bonus, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->incentive > 0)
        <tr>
            <td>Insentif</td>
            <td class="amount">Rp {{ number_format($payroll->incentive, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->holiday_allowance > 0)
        <tr>
            <td>THR / Insentif Lebaran</td>
            <td class="amount">Rp {{ number_format($payroll->holiday_allowance, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->policy_ho > 0)
        <tr>
            <td>Kebijakan HO</td>
            <td class="amount">Rp {{ number_format($payroll->policy_ho, 0, ',', '.') }}</td>
        </tr>
        @endif
        
         <tr style="height: 10px;"></tr>
         <tr>
            <td style="font-weight: bold;">TOTAL PENDAPATAN KOTOR</td>
            <td class="amount" style="font-weight: bold;">Rp {{ number_format($payroll->total_salary_2 > 0 ? $payroll->total_salary_2 : ($payroll->net_salary + $payroll->deduction_total), 0, ',', '.') }}</td>
        </tr>
    </table>

    <div class="section-title">POTONGAN (DEDUCTIONS)</div>
    <table class="details-table">
        @if($payroll->deduction_absent > 0)
        <tr>
            <td>Potongan Absen (Absen 1X)</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_absent, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->deduction_late > 0)
        <tr>
            <td>Terlambat</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_late, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->deduction_alpha > 0)
        <tr>
            <td>Tidak Hadir (Alpha)</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_alpha, 0, ',', '.') }}</td>
        </tr>
        @endif
        
         @if($payroll->deduction_loan > 0)
        <tr>
            <td>Pinjaman</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_loan, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->deduction_admin_fee > 0)
        <tr>
            <td>Admin Bank</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_admin_fee, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        @if($payroll->deduction_bpjs_tk > 0)
        <tr>
            <td>BPJS Ketenagakerjaan</td>
            <td class="amount">Rp {{ number_format($payroll->deduction_bpjs_tk, 0, ',', '.') }}</td>
        </tr>
        @endif
        
        <tr style="height: 5px;"></tr>
        <tr>
            <td style="font-weight: bold; color: #d32f2f;">TOTAL POTONGAN</td>
            <td class="amount" style="font-weight: bold; color: #d32f2f;">(Rp {{ number_format($payroll->deduction_total, 0, ',', '.') }})</td>
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
                <td style="font-size: 14px; font-weight: bold;">GAJI BERSIH (NET SALARY)</td>
                <td style="font-size: 16px; font-weight: bold; text-align: right;">Rp {{ number_format($payroll->net_salary, 0, ',', '.') }}</td>
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
