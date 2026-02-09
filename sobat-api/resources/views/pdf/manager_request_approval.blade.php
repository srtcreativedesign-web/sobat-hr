<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Form Pengajuan - {{ $request->title }}</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 12px; line-height: 1.5; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #333; padding-bottom: 10px; }
        .header h1 { margin: 0; font-size: 18px; }
        .header h2 { margin: 5px 0; font-size: 14px; font-weight: normal; }
        .info-table { width: 100%; margin-bottom: 20px; }
        .info-table td { padding: 5px; vertical-align: top; }
        .info-table .label { font-weight: bold; width: 150px; }
        .detail-box { border: 1px solid #ccc; padding: 15px; margin-bottom: 20px; background: #f9f9f9; }
        .signature-section { margin-top: 40px; }
        .signature-table { width: 100%; }
        .signature-box { width: 200px; text-align: center; padding: 10px; border: 1px solid #ccc; }
        .signature-box .title { font-weight: bold; margin-bottom: 5px; }
        .signature-box .line { border-bottom: 1px solid #333; height: 60px; margin: 20px 10px; }
        .signature-box .name { font-size: 10px; color: #666; }
        .footer { margin-top: 30px; font-size: 10px; color: #666; text-align: center; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 10px; font-weight: bold; }
        .badge-warning { background: #ffc107; color: #333; }
        .badge-info { background: #17a2b8; color: #fff; }
    </style>
</head>
<body>
    <div class="header">
        <h1>FORM PENGAJUAN</h1>
        <h2>{{ strtoupper($request->type) }} - {{ $request->title }}</h2>
        <span class="badge badge-warning">MENUNGGU APPROVAL COO</span>
    </div>

    <table class="info-table">
        <tr>
            <td class="label">No. Pengajuan</td>
            <td>: REQ-{{ str_pad($request->id, 5, '0', STR_PAD_LEFT) }}</td>
            <td class="label">Tanggal Pengajuan</td>
            <td>: {{ $request->created_at->format('d M Y') }}</td>
        </tr>
        <tr>
            <td class="label">Nama Pemohon</td>
            <td>: {{ $requester->full_name }}</td>
            <td class="label">Jabatan</td>
            <td>: {{ $requesterRole }}</td>
        </tr>
        <tr>
            <td class="label">Divisi/Cabang</td>
            <td>: {{ $requester->organization?->name ?? '-' }}</td>
            <td class="label">Status</td>
            <td>: <span class="badge badge-info">{{ strtoupper($request->status) }}</span></td>
        </tr>
    </table>

    <div class="detail-box">
        <strong>Detail Pengajuan:</strong>
        <p>{{ $request->description }}</p>
        
        @if($request->start_date)
        <p><strong>Periode:</strong> {{ \Carbon\Carbon::parse($request->start_date)->format('d M Y') }} 
            @if($request->end_date && $request->end_date != $request->start_date)
            s/d {{ \Carbon\Carbon::parse($request->end_date)->format('d M Y') }}
            @endif
        </p>
        @endif
        
        @if($request->amount)
        <p><strong>Jumlah/Nominal:</strong> 
            @if($request->type == 'reimbursement' || $request->type == 'business_trip')
                Rp {{ number_format($request->amount, 0, ',', '.') }}
            @else
                {{ $request->amount }} hari
            @endif
        </p>
        @endif
        
        @if($request->reason && $request->reason != $request->description)
        <p><strong>Alasan:</strong> {{ $request->reason }}</p>
        @endif
    </div>

    <div class="signature-section">
        <table class="signature-table">
            <tr>
                <td style="width: 33%; text-align: center;">
                    <div class="signature-box">
                        <div class="title">Pemohon</div>
                        <div class="line"></div>
                        <div class="name">{{ $requester->full_name }}</div>
                        <div class="name">{{ $requesterRole }}</div>
                    </div>
                </td>
                <td style="width: 33%; text-align: center;">
                    <div class="signature-box">
                        <div class="title">Mengetahui</div>
                        <div class="line"></div>
                        <div class="name">___________________</div>
                        <div class="name">Manager HRD</div>
                    </div>
                </td>
                <td style="width: 33%; text-align: center;">
                    <div class="signature-box">
                        <div class="title">Menyetujui</div>
                        <div class="line"></div>
                        <div class="name">___________________</div>
                        <div class="name">COO / Direktur Operasional</div>
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <div class="footer">
        <p>Dicetak pada: {{ $printedAt->format('d M Y H:i') }} oleh {{ $printedBy }}</p>
        <p><em>Dokumen ini dicetak untuk keperluan approval offline. Harap ditandatangani dan diserahkan ke HRD.</em></p>
    </div>
</body>
</html>
