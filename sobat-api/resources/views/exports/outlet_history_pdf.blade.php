<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Riwayat Absensi Outlet</title>
    <style>
        body { font-family: sans-serif; font-size: 12px; }
        .header { text-align: center; margin-bottom: 20px; }
        .header h2 { margin: 0; padding: 0; }
        .header p { margin: 5px 0; color: #555; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
        .text-center { text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h2>Riwayat Absensi Outlet</h2>
        <p><strong>Outlet:</strong> {{ $organization->name ?? 'Outlet' }}</p>
        <p><strong>Tanggal:</strong> {{ $date }}</p>
        <p><strong>Perangkat:</strong> {{ $device_name }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 5%">No</th>
                <th style="width: 20%">ID Karyawan</th>
                <th style="width: 35%">Nama Lengkap</th>
                <th style="width: 20%" class="text-center">Waktu Check-In</th>
                <th style="width: 20%" class="text-center">Waktu Check-Out</th>
            </tr>
        </thead>
        <tbody>
            @forelse($history as $index => $log)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td>{{ optional($log->employee)->employee_code ?? '-' }}</td>
                    <td>{{ optional($log->employee)->full_name ?? '-' }}</td>
                    <td class="text-center">{{ $log->check_in ? \Carbon\Carbon::parse($log->check_in)->format('H:i:s') : '-' }}</td>
                    <td class="text-center">{{ $log->check_out ? \Carbon\Carbon::parse($log->check_out)->format('H:i:s') : '-' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="text-center">Tidak ada data absensi untuk hari ini.</td>
                </tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
