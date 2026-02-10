<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Slip Gaji Head Office</title>
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
            border-bottom: 2px solid #1a3a5c;
            padding-bottom: 5px;
        }
        .company-name {
            font-size: 16px;
            font-weight: bold;
            color: #1a3a5c;
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
            background-color: #e3edf7;
            color: #1a3a5c;
            padding: 4px 8px;
            font-weight: bold;
            margin-top: 10px;
            margin-bottom: 5px;
            border-left: 4px solid #1a3a5c;
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
            background-color: #1a3a5c;
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
        <div style="font-size: 11px; color: #1a3a5c;">HEAD OFFICE</div>
        <div class="period">PERIODE: {{ strtoupper(\Carbon\Carbon::parse($payroll->period . '-01')->translatedFormat('F Y')) }}</div>
    </div>

    <table class="info-table">
        <tr>
            <td class="info-label">Nama</td>
            <td>: {{ strtoupper($payroll->employee->full_name) }}</td>
            <td class="info-label" style="text-align: right;">No. Slip</td>
            <td style="width: 100px; text-align: right;">: SAL-HO-{{ $payroll->id }}</td>
        </tr>
        <tr>
            <td class="info-label">Divisi</td>
            <td>: HEAD OFFICE</td>
            <td class="info-label" style="text-align: right;">Tanggal</td>
            <td style="text-align: right;">: {{ date('d/m/Y') }}</td>
        </tr>
        <tr>
            <td class="info-label">Jabatan</td>
            <td>: {{ $payroll->employee->position ?? '-' }}</td>
            <td class="info-label" style="text-align: right;">No. Rekening</td>
            <td style="text-align: right;">: {{ $details['account_number'] ?? ($payroll->account_number ?? '-') }}</td>
        </tr>
    </table>

    @php
        $details = $payroll->details ?? [];
        $deductions = $details['deductions'] ?? [];

        // Income components
        $basicSalary = $payroll->basic_salary ?? 0;
        $daysPresent = $details['days_present'] ?? ($payroll->days_present ?? 0);

        // Transport
        $transportRate = $details['transport_rate'] ?? ($payroll->transport_rate ?? 0);
        $transportAmount = $details['transport_allowance'] ?? ($payroll->transport_amount ?? 0);

        // Kehadiran
        $attendanceRate = $details['attendance_rate'] ?? ($payroll->attendance_rate ?? 0);
        $attendanceAmount = $details['attendance_allowance'] ?? ($payroll->attendance_amount ?? 0);

        // Lembur
        $overtimeHours = $details['overtime_hours'] ?? ($payroll->overtime_hours ?? 0);
        $overtimeRate = $details['overtime_rate'] ?? ($payroll->overtime_rate ?? 0);
        $overtimeAmount = $details['overtime_amount'] ?? ($payroll->overtime_amount ?? ($payroll->overtime_pay ?? 0));

        // Tunjangan
        $positionAllowance = $details['position_allowance'] ?? ($payroll->position_allowance ?? 0);
        $healthAllowance = $details['health_allowance'] ?? ($payroll->health_allowance ?? 0);

        // Insentif & Lainnya
        $insentifLuarKota = $details['insentif_luar_kota'] ?? ($payroll->insentif_luar_kota ?? 0);
        $insentifKehadiran = $details['insentif_kehadiran'] ?? ($payroll->insentif_kehadiran ?? 0);
        $adjGaji = $details['adjustment'] ?? ($payroll->adjustment ?? 0);
        $piketUmSabtu = $details['piket_um_sabtu'] ?? ($payroll->piket_um_sabtu ?? 0);

        // Total Gaji = Pokok + Transport + Kehadiran + Lembur
        $totalGaji = $details['total_gaji'] ?? ($basicSalary + $transportAmount + $attendanceAmount + $overtimeAmount);

        // Gaji Diterima = Total + Tunjangan + Insentif
        $gajiDiterima = $details['gaji_diterima'] ?? ($totalGaji + $positionAllowance + $healthAllowance + $insentifLuarKota + $insentifKehadiran + $adjGaji + $piketUmSabtu);

        // Potongan
        $kasbon = $deductions['loan'] ?? ($payroll->deduction_loan ?? 0);
        $alfa = $deductions['alfa'] ?? ($deductions['absent'] ?? ($payroll->deduction_absent ?? 0));
        $potEwa = $details['ewa'] ?? ($payroll->ewa_amount ?? 0);

        $totalPotongan = $kasbon + $alfa + $potEwa;

        // Gaji Bersih
        $gajiBersih = $payroll->net_salary ?? ($gajiDiterima - $totalPotongan);
    @endphp

    <div class="section-title">PENDAPATAN (INCOME)</div>
    <table class="details-table">
        <tr>
            <td>Gaji Pokok</td>
            <td class="amount">Rp {{ number_format($basicSalary, 0, ',', '.') }}</td>
        </tr>

        @if($transportAmount > 0)
        <tr>
            <td>Transport ({{ number_format($transportRate, 0) }} x {{ $daysPresent }} hari)</td>
            <td class="amount">Rp {{ number_format($transportAmount, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($attendanceAmount > 0)
        <tr>
            <td>Uang Kehadiran ({{ number_format($attendanceRate, 0) }} x {{ $daysPresent }} hari)</td>
            <td class="amount">Rp {{ number_format($attendanceAmount, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($overtimeAmount > 0)
        <tr>
            <td>Lembur ({{ $overtimeHours }} Jam)</td>
            <td class="amount">Rp {{ number_format($overtimeAmount, 0, ',', '.') }}</td>
        </tr>
        @endif

        <tr style="height: 5px;"></tr>
        <tr class="subtotal">
            <td>Total Gaji</td>
            <td class="amount">Rp {{ number_format($totalGaji, 0, ',', '.') }}</td>
        </tr>
    </table>

    <div class="section-title">TUNJANGAN & INSENTIF</div>
    <table class="details-table">
        @if($positionAllowance > 0)
        <tr>
            <td>Tunjangan Jabatan</td>
            <td class="amount">Rp {{ number_format($positionAllowance, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($healthAllowance > 0)
        <tr>
            <td>Tunjangan Kesehatan</td>
            <td class="amount">Rp {{ number_format($healthAllowance, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($insentifLuarKota > 0)
        <tr>
            <td>Insentif Luar Kota</td>
            <td class="amount">Rp {{ number_format($insentifLuarKota, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($insentifKehadiran > 0)
        <tr>
            <td>Insentif Kehadiran</td>
            <td class="amount">Rp {{ number_format($insentifKehadiran, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($adjGaji > 0)
        <tr>
            <td>Adj Gaji</td>
            <td class="amount">Rp {{ number_format($adjGaji, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($piketUmSabtu > 0)
        <tr>
            <td>Piket & UM Sabtu</td>
            <td class="amount">Rp {{ number_format($piketUmSabtu, 0, ',', '.') }}</td>
        </tr>
        @endif

        <tr style="height: 5px;"></tr>
        <tr class="subtotal">
            <td style="font-weight: bold;">GAJI DITERIMA (KOTOR)</td>
            <td class="amount" style="font-weight: bold;">Rp {{ number_format($gajiDiterima, 0, ',', '.') }}</td>
        </tr>
    </table>

    <div class="section-title">POTONGAN (DEDUCTIONS)</div>
    <table class="details-table">
        @if($kasbon > 0)
        <tr>
            <td>Kasbon</td>
            <td class="amount">Rp {{ number_format($kasbon, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($alfa > 0)
        <tr>
            <td>ALFA (Tanpa Keterangan)</td>
            <td class="amount">Rp {{ number_format($alfa, 0, ',', '.') }}</td>
        </tr>
        @endif

        @if($potEwa > 0)
        <tr>
            <td>Potongan EWA</td>
            <td class="amount">Rp {{ number_format($potEwa, 0, ',', '.') }}</td>
        </tr>
        @endif

        <tr style="height: 5px;"></tr>
        <tr>
            <td style="font-weight: bold; color: #d32f2f;">TOTAL POTONGAN</td>
            <td class="amount" style="font-weight: bold; color: #d32f2f;">(Rp {{ number_format($totalPotongan, 0, ',', '.') }})</td>
        </tr>
    </table>

    <div class="total-section">
        <table style="width: 100%;">
            <tr>
                <td style="font-size: 14px; font-weight: bold;">GAJI BERSIH (NET SALARY)</td>
                <td style="font-size: 16px; font-weight: bold; text-align: right;">Rp {{ number_format($gajiBersih, 0, ',', '.') }}</td>
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
