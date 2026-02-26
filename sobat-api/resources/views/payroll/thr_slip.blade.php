<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <title>Slip THR - {{ $employee->full_name }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            font-size: 11px;
            color: #333;
            line-height: 1.4;
        }

        .container {
            padding: 20px;
            max-width: 100%;
        }

        .header {
            background: linear-gradient(135deg, #06B6D4 0%, #3B82F6 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }

        .header h1 {
            font-size: 20px;
            letter-spacing: 2px;
            margin-bottom: 5px;
        }

        .header .company {
            font-size: 12px;
            opacity: 0.9;
        }

        .info-section {
            margin-bottom: 25px;
            background: #f8fafc;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
        }

        .info-grid {
            display: table;
            width: 100%;
        }

        .info-row {
            display: table-row;
        }

        .info-label {
            display: table-cell;
            width: 30%;
            padding: 4px 0;
            font-weight: bold;
            color: #64748b;
        }

        .info-value {
            display: table-cell;
            padding: 4px 0;
        }

        .content-section {
            margin-bottom: 30px;
        }

        .content-title {
            font-size: 14px;
            font-weight: bold;
            color: #06B6D4;
            border-bottom: 2px solid #06B6D4;
            padding-bottom: 5px;
            margin-bottom: 15px;
            text-transform: uppercase;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            text-align: left;
            padding: 10px;
            background: #f1f5f9;
            color: #475569;
            font-size: 10px;
            text-transform: uppercase;
        }

        td {
            padding: 12px 10px;
            border-bottom: 1px solid #e2e8f0;
        }

        .amount {
            text-align: right;
            font-family: 'Courier New', Courier, monospace;
            font-weight: bold;
        }

        .summary-table {
            margin-top: 20px;
            border: 2px solid #06B6D4;
            border-radius: 8px;
            overflow: hidden;
            background: #ecfeff;
        }

        .summary-row {
            display: table;
            width: 100%;
        }

        .summary-label {
            display: table-cell;
            padding: 15px;
            font-size: 14px;
            font-weight: bold;
            color: #0e7490;
        }

        .summary-value {
            display: table-cell;
            padding: 15px;
            text-align: right;
            font-size: 18px;
            font-weight: bold;
            color: #0891b2;
        }

        .signature-section {
            margin-top: 50px;
            width: 100%;
        }

        .signature-table {
            width: 100%;
        }

        .signature-box {
            text-align: center;
            width: 50%;
        }

        .signature-space {
            height: 80px;
        }

        .footer {
            margin-top: 50px;
            text-align: center;
            color: #94a3b8;
            font-size: 9px;
            border-top: 1px solid #e2e8f0;
            padding-top: 15px;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>SLIP TUNJANGAN HARI RAYA</h1>
            <div class="company">PT Mandala Karya Sentosa</div>
        </div>

        <div class="info-section">
            <div class="info-grid">
                <div class="info-row">
                    <div class="info-label">Nama Karyawan</div>
                    <div class="info-value">: {{ $employee->full_name }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">NIK</div>
                    <div class="info-value">: {{ $employee->employee_code }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Jabatan</div>
                    <div class="info-value">: {{ $employee->position ?? '-' }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Masa Kerja</div>
                    <div class="info-value">: {{ $masaKerja }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Tahun</div>
                    <div class="info-value">: {{ $thr->year }}</div>
                </div>
            </div>
        </div>

        <div class="content-section">
            <div class="content-title">Rincian Penerimaan</div>
            <table>
                <thead>
                    <tr>
                        <th>Keterangan</th>
                        <th style="text-align: right;">Jumlah (Rp)</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Tunjangan Hari Raya (THR)</td>
                        <td class="amount">{{ number_format($thr->amount, 0, ',', '.') }}</td>
                    </tr>
                </tbody>
            </table>

            <div class="summary-table">
                <div class="summary-row">
                    <div class="summary-label">TOTAL DITERIMA</div>
                    <div class="summary-value">Rp {{ number_format($thr->amount, 0, ',', '.') }}</div>
                </div>
            </div>
        </div>

        <table class="signature-table">
            <tr>
                <td class="signature-box" style="border: none;">
                    <p>Diterima oleh,</p>
                    <div class="signature-space">
                        @if(!empty($employeeSignature))
                            <img src="{{ $employeeSignature }}" alt="Employee Signature" style="height: 60px;">
                        @endif
                    </div>
                    <p><strong>{{ $employee->full_name }}</strong></p>
                </td>
                <td class="signature-box" style="border: none;">
                    <p>Disetujui oleh,</p>
                    <div class="signature-space">
                        @if(!empty($thr->details['signature']))
                            <img src="{{ $thr->details['signature'] }}" alt="Signature" style="height: 60px;">
                        @endif
                    </div>
                    <p><strong>{{ $thr->details['signer_name'] ?? 'Management' }}</strong></p>
                </td>
            </tr>
        </table>

        <div class="footer">
            <p>Dokumen ini diterbitkan secara elektronik oleh SOBAT HR System.</p>
            <p>Dicetak pada: {{ date('d/m/Y H:i:s') }}</p>
        </div>
    </div>
</body>

</html>
