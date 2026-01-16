<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <title>Slip Gaji - {{ $employee->full_name }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            font-size: 10px;
            color: #333;
            line-height: 1.4;
        }

        .container {
            padding: 15px 20px;
            max-width: 100%;
        }

        .header {
            background: linear-gradient(135deg, #1A4D2E 0%, #2d7a4a 100%);
            color: white;
            padding: 12px 15px;
            border-radius: 6px 6px 0 0;
            margin-bottom: 12px;
        }

        .header h1 {
            font-size: 20px;
            margin-bottom: 2px;
        }

        .header .company {
            font-size: 11px;
            opacity: 0.9;
        }

        .info-section {
            margin-bottom: 12px;
        }

        .info-grid {
            display: table;
            width: 100%;
            margin-bottom: 10px;
        }

        .info-row {
            display: table-row;
        }

        .info-label {
            display: table-cell;
            width: 160px;
            font-weight: bold;
            color: #555;
            padding: 3px 0;
            font-size: 10px;
        }

        .info-value {
            display: table-cell;
            padding: 3px 0;
            color: #333;
            font-size: 10px;
        }

        .divider {
            border-top: 1px solid #e5e7eb;
            margin: 12px 0;
        }

        h3 {
            font-size: 12px;
            margin-bottom: 8px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
        }

        th {
            background: #f9fafb;
            color: #1A4D2E;
            text-align: left;
            padding: 6px 8px;
            font-weight: bold;
            border-bottom: 2px solid #1A4D2E;
            font-size: 10px;
        }

        td {
            padding: 5px 8px;
            border-bottom: 1px solid #e5e7eb;
            font-size: 10px;
        }

        .amount {
            text-align: right;
            font-weight: 600;
        }

        .positive {
            color: #059669;
        }

        .negative {
            color: #dc2626;
        }

        .summary {
            background: #f0fdf4;
            border: 2px solid #1A4D2E;
            border-radius: 6px;
            padding: 12px;
            margin: 12px 0;
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 4px 0;
            font-size: 11px;
        }

        .summary-total {
            font-size: 14px;
            font-weight: bold;
            color: #1A4D2E;
            border-top: 2px solid #1A4D2E;
            padding-top: 8px;
            margin-top: 6px;
        }

        .ai-message {
            background: #eff6ff;
            border-left: 3px solid #3b82f6;
            padding: 10px;
            margin: 12px 0;
            border-radius: 4px;
            font-style: italic;
            color: #1e40af;
            line-height: 1.5;
            font-size: 9px;
        }

        .footer {
            text-align: center;
            color: #6b7280;
            font-size: 8px;
            margin-top: 15px;
            padding-top: 10px;
            border-top: 1px solid #e5e7eb;
        }

        @page {
            margin: 10mm 15mm;
        }

        @media print {
            .container {
                padding: 0;
            }

            body {
                font-size: 10px;
            }
        }
    </style>
</head>

<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>SLIP GAJI</h1>
            <div class="company">PT Mandala Karya Sentosa</div>
        </div>

        <!-- Employee Info -->
        <div class="info-section">
            <div class="info-grid">
                <div class="info-row">
                    <div class="info-label">Nama Karyawan</div>
                    <div class="info-value">: {{ $employee->full_name }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">NIK / Employee Code</div>
                    <div class="info-value">: {{ $employee->employee_code }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Jabatan</div>
                    <div class="info-value">: {{ $employee->position ?? '-' }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Departemen</div>
                    <div class="info-value">: {{ $employee->organization->name ?? '-' }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Periode</div>
                    <div class="info-value">: {{ date('F Y', strtotime($payroll->period . '-01')) }}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Tanggal Cetak</div>
                    <div class="info-value">: {{ date('d F Y') }}</div>
                </div>
            </div>
        </div>

        <div class="divider"></div>

        <!-- Income Details -->
        <h3 style="color: #1A4D2E; margin-bottom: 15px;">PENGHASILAN</h3>
        <table>
            <thead>
                <tr>
                    <th>Komponen</th>
                    <th style="text-align: right;">Jumlah (Rp)</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Gaji Pokok</td>
                    <td class="amount positive">{{ number_format($payroll->basic_salary, 0, ',', '.') }}</td>
                </tr>
                @if(isset($payroll->details) && count($payroll->details) > 0)
                    <!-- Detailed View -->
                    @if(!empty($payroll->details['tunjangan_kesehatan']))
                    <tr>
                        <td>Tunjangan Kesehatan</td>
                        <td class="amount positive">{{ number_format($payroll->details['tunjangan_kesehatan'], 0, ',', '.') }}</td>
                    </tr>
                    @endif
                     @if(!empty($payroll->allowances) && empty($payroll->details['tunjangan_kesehatan']))
                         <!-- Fallback for standard allowances if no breakdown -->
                        <tr>
                            <td>Tunjangan Jabatan</td>
                            <td class="amount positive">{{ number_format($payroll->allowances, 0, ',', '.') }}</td>
                        </tr>
                    @elseif(!empty($payroll->allowances))
                         <!-- Tunj. Jabatan is usually the diff between Total Allowances and other components?
                              Actually, in import: basic + tunjJab + tunjKes + transport + insentif = gross.
                              The DB 'allowances' column stores sum(tunjJab + tunjKes + transport + insentif).
                              So if we list them individually, we should NOT show the aggregated 'allowances' row.
                              We need to calculate Tunj. Jabatan explicitly?
                              In import: 'allowances' = tunjJab + tunjKes + transport + insentif.
                              We didn't store 'tunjangan_jabatan' in details! We mapped Q directly to 'allowances' but then SUMMED it.
                              Wait, check import logic:
                              $allowances = $extract(16); // Tunj Jabatan
                              ...
                              'allowances' => $allowances + $tunjKesehatan + $transportAllowance + $insentif,
                              
                              ISSUE: We lost the raw 'Tunjangan Jabatan' value in the DB column because we overwrote it with the sum.
                              But we DID NOT save 'tunjangan_jabatan' in details.
                              We saved: transport, tunj_kesehatan, insentif.
                              So 'Tunjangan Jabatan' = $payroll->allowances - (transport + tunj_kesehatan + insentif).
                          -->
                        @php
                            $totalStoredAllowances = $payroll->allowances;
                            $transport = $payroll->details['transport_allowance'] ?? 0;
                            $tunjKes = $payroll->details['tunjangan_kesehatan'] ?? 0;
                            $insentif = $payroll->details['insentif_lebaran'] ?? 0;
                            
                            $tunjJabatan = $totalStoredAllowances - ($transport + $tunjKes + $insentif);
                        @endphp
                        @if($tunjJabatan > 0)
                        <tr>
                            <td>Tunjangan Jabatan</td>
                            <td class="amount positive">{{ number_format($tunjJabatan, 0, ',', '.') }}</td>
                        </tr>
                        @endif
                    @endif

                    @if(!empty($payroll->details['transport_allowance']))
                    <tr>
                        <td>Transport</td>
                        <td class="amount positive">{{ number_format($payroll->details['transport_allowance'], 0, ',', '.') }}</td>
                    </tr>
                    @endif
                    
                    @if(!empty($payroll->details['insentif_lebaran']))
                    <tr>
                        <td>Insentif Lebaran</td>
                        <td class="amount positive">{{ number_format($payroll->details['insentif_lebaran'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                    @if(!empty($payroll->details['adj_kekurangan_gaji']))
                    <tr>
                        <td>Adjustment Kekurangan Gaji</td>
                        <td class="amount positive">{{ number_format($payroll->details['adj_kekurangan_gaji'], 0, ',', '.') }}</td>
                    </tr>
                    @endif
                    
                    @if(!empty($payroll->details['kebijakan_ho']) && $payroll->details['kebijakan_ho'] > 0)
                    <tr>
                        <td>Kebijakan HO</td>
                        <td class="amount positive">{{ number_format($payroll->details['kebijakan_ho'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                @else
                    <!-- Simple View (Backward Compatibility) -->
                    <tr>
                        <td>Tunjangan</td>
                        <td class="amount positive">{{ number_format($payroll->allowances ?? 0, 0, ',', '.') }}</td>
                    </tr>
                @endif
                
                <tr>
                    <td>Uang Lembur</td>
                    <td class="amount positive">{{ number_format($payroll->overtime_pay ?? 0, 0, ',', '.') }}</td>
                </tr>
                <tr style="background: #f9fafb; font-weight: bold;">
                    <td>TOTAL PENGHASILAN</td>
                    @php
                        $gross_salary = $payroll->gross_salary; // Use pre-calculated gross from DB
                    @endphp
                    <td class="amount">{{ number_format($gross_salary, 0, ',', '.') }}</td>
                </tr>
            </tbody>
        </table>

        <!-- Deductions -->
        <h3 style="color: #dc2626; margin-bottom: 15px; margin-top: 25px;">POTONGAN</h3>
        <table>
            <thead>
                <tr>
                    <th>Komponen</th>
                    <th style="text-align: right;">Jumlah (Rp)</th>
                </tr>
            </thead>
            <tbody>
                <!-- Standard Deductions (Always shown if present) -->
                @if($payroll->bpjs_kesehatan > 0)
                <tr>
                    <td>BPJS Kesehatan</td>
                    <td class="amount negative">{{ number_format($payroll->bpjs_kesehatan, 0, ',', '.') }}</td>
                </tr>
                @endif
                
                @if($payroll->bpjs_ketenagakerjaan > 0)
                <tr>
                    <td>BPJS Ketenagakerjaan</td>
                    <td class="amount negative">{{ number_format($payroll->bpjs_ketenagakerjaan, 0, ',', '.') }}
                    </td>
                </tr>
                @endif
                
                @if($payroll->pph21 > 0)
                <tr>
                    <td>PPh 21</td>
                    <td class="amount negative">{{ number_format($payroll->pph21, 0, ',', '.') }}</td>
                </tr>
                @endif

                @if(isset($payroll->details) && count($payroll->details) > 0)
                    <!-- Detailed Deductions -->
                    @if(!empty($payroll->details['absen_1x']))
                    <tr>
                        <td>Potongan Absen</td>
                        <td class="amount negative">{{ number_format($payroll->details['absen_1x'], 0, ',', '.') }}</td>
                    </tr>
                    @endif
                    
                    @if(!empty($payroll->details['terlambat']))
                    <tr>
                        <td>Denda Terlambat</td>
                        <td class="amount negative">{{ number_format($payroll->details['terlambat'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                    @if(!empty($payroll->details['selisih_so']))
                    <tr>
                        <td>Selisih SO</td>
                        <td class="amount negative">{{ number_format($payroll->details['selisih_so'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                    @if(!empty($payroll->details['pinjaman']))
                    <tr>
                        <td>Pinjaman / Kasbon</td>
                        <td class="amount negative">{{ number_format($payroll->details['pinjaman'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                    @if(!empty($payroll->details['adm_bank']))
                    <tr>
                        <td>Admin Bank</td>
                        <td class="amount negative">{{ number_format($payroll->details['adm_bank'], 0, ',', '.') }}</td>
                    </tr>
                    @endif

                    <!-- Check if there are other generic deductions remaining? -->
                    @if($payroll->other_deductions > 0)
                    <tr>
                        <td>Potongan Lain-lain</td>
                        <td class="amount negative">{{ number_format($payroll->other_deductions, 0, ',', '.') }}</td>
                    </tr>
                    @endif

                @else
                    <!-- Simple View -->
                    @if(($payroll->other_deductions ?? 0) > 0)
                    <tr>
                        <td>Potongan Lain-lain</td>
                        <td class="amount negative">{{ number_format($payroll->other_deductions ?? 0, 0, ',', '.') }}</td>
                    </tr>
                    @endif
                @endif

                <tr style="background: #fee2e2; font-weight: bold;">
                    <td>TOTAL POTONGAN</td>
                    @php
                        $total_deductions = $payroll->total_deductions;
                    @endphp
                    <td class="amount">{{ number_format($total_deductions, 0, ',', '.') }}</td>
                </tr>
            </tbody>
        </table>

        <!-- Summary -->
        <div class="summary">
            <div class="summary-row">
                <span>Total Penghasilan</span>
                <span>Rp {{ number_format($gross_salary, 0, ',', '.') }}</span>
            </div>
            <div class="summary-row">
                <span>Total Potongan</span>
                <span>(Rp {{ number_format($total_deductions, 0, ',', '.') }})</span>
            </div>
            <div class="summary-total summary-row">
                <span>TAKE HOME PAY</span>
                <span>Rp {{ number_format($gross_salary - $total_deductions, 0, ',', '.') }}</span>
            </div>
        </div>

        <!-- AI Generated Message -->
        @if(!empty($aiMessage))
            <div class="ai-message">
                <strong style="display: block; margin-bottom: 8px; color: #1e40af;">📌 Pesan untuk Anda:</strong>
                {{ $aiMessage }}
            </div>
        @endif

        <!-- Footer -->
        <div class="footer">
            <p>Dokumen ini digenerate secara otomatis oleh sistem SOBAT HR</p>
            <p style="margin-top: 5px;">Untuk pertanyaan, hubungi HR Department</p>
            <p style="margin-top: 10px; font-size: 10px; color: #9ca3af;">AI-Enhanced Payslip Generator • Powered by
                SOBAT © 2026</p>
        </div>
    </div>
</body>

</html>