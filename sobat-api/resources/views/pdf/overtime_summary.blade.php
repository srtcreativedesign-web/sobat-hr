<!DOCTYPE html>
<html>
<head>
    <title>Rekap Pengajuan Lembur</title>
    <style>
        body { font-family: sans-serif; font-size: 11px; }
        .header { text-align: center; margin-bottom: 20px; }
        .title { font-size: 18px; font-weight: bold; margin-bottom: 5px; }
        .subtitle { color: #666; font-size: 12px; }
        .info-table { width: 50%; margin-bottom: 20px; border-collapse: collapse; }
        .info-table th, .info-table td { padding: 4px; text-align: left; border: none; font-size: 12px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table, th, td { border: 1px solid #333; }
        th, td { padding: 8px; text-align: left; }
        th { background-color: #f5f5f5; text-align: center; }
        .text-center { text-align: center; }
        .signature-table { width: 100%; border: none; margin-top: 50px; }
        .signature-table td { border: none; text-align: center; width: 33%; vertical-align: bottom; height: 100px; }
        .signature-line { border-bottom: 1px solid #000; width: 80%; margin: 0 auto; margin-bottom: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">REKAPITULASI PENGAJUAN LEMBUR</div>
        <div class="subtitle">Dicetak pada: {{ now()->format('d M Y H:i') }}</div>
    </div>

    @if($requests->isNotEmpty())
        @php
            $employee = $requests->first()->employee;
        @endphp
        <table class="info-table">
            <tr>
                <th width="100">Nama</th>
                <td>: {{ $employee->full_name ?? '-' }}</td>
            </tr>
            <tr>
                <th>NIK</th>
                <td>: {{ $employee->employee_code ?? '-' }}</td>
            </tr>
            <tr>
                <th>Departemen</th>
                <td>: {{ $employee->department ?? '-' }}</td>
            </tr>
            <tr>
                <th>Periode</th>
                <td>: {{ request('month') && request('year') ? request('month') . '/' . request('year') : 'Semua Periode' }}</td>
            </tr>
        </table>
    @endif

    <table>
        <thead>
            <tr>
                <th width="30">No</th>
                <th width="80">Tanggal</th>
                <th width="60">Mulai</th>
                <th width="60">Selesai</th>
                <th width="60">Durasi</th>
                <th>Keterangan / Pekerjaan</th>
                <th width="80">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse($requests as $index => $req)
                @php
                    $detail = $req->overtimeDetail;
                    $durationHours = $detail ? number_format($detail->duration / 60, 2) : ($req->amount ?? 0);
                @endphp
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td class="text-center">{{ $req->start_date ? \Carbon\Carbon::parse($req->start_date)->format('d/m/Y') : '-' }}</td>
                    <td class="text-center">{{ $detail ? \Carbon\Carbon::parse($detail->start_time)->format('H:i') : '-' }}</td>
                    <td class="text-center">{{ $detail ? \Carbon\Carbon::parse($detail->end_time)->format('H:i') : '-' }}</td>
                    <td class="text-center">{{ $durationHours }} Jam</td>
                    <td>{{ $req->reason ?? $req->description }}</td>
                    <td class="text-center">{{ ucfirst($req->status) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center">Tidak ada data pengajuan lembur yang disetujui pada periode ini.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <table class="signature-table">
        <tr>
            <td>
                <br><br><br><br>
                <div class="signature-line"></div>
                <strong>{{ $requests->isNotEmpty() ? ($requests->first()->employee->full_name ?? 'Pemohon') : 'Pemohon' }}</strong><br>
                Karyawan
            </td>
            <td>
                <br><br><br><br>
                <div class="signature-line"></div>
                <strong>Atasan Langsung</strong><br>
                Mengetahui
            </td>
            <td>
                <br><br><br><br>
                <div class="signature-line"></div>
                <strong>HRD / Manajemen</strong><br>
                Menyetujui
            </td>
        </tr>
    </table>

    <div style="margin-top: 30px; font-size: 9px; color: #888;">
        * Dokumen ini digenerate secara otomatis oleh sistem SOBAT-HR dan sah untuk digunakan sebagai lampiran administrasi.
    </div>
</body>
</html>
