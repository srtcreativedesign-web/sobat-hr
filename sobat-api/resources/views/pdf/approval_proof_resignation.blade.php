<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Surat Pengunduran Diri</title>
    <style>
        body { font-family: "Times New Roman", Times, serif; color: #000; line-height: 1.6; font-size: 14px; margin: 40px; }
        .header { text-align: center; margin-bottom: 40px; }
        .title { font-size: 18px; font-weight: bold; text-decoration: underline; text-transform: uppercase; }
        
        .content { margin-bottom: 20px; }
        .paragraph { margin-bottom: 15px; text-align: justify; }
        
        .identity { margin-left: 20px; margin-bottom: 20px; }
        .row { display: table; margin-bottom: 5px; }
        .label { display: table-cell; width: 150px; }
        .sep { display: table-cell; width: 20px; }
        .value { display: table-cell; font-weight: bold; }

        .footer { margin-top: 60px; text-align: right; margin-right: 50px; }
        .signature-box { margin-top: 20px; margin-bottom: 60px; }
        
        .approval-section { margin-top: 50px; border-top: 1px solid #ccc; padding-top: 20px; font-size: 12px; color: #555; font-family: sans-serif; }
        .status-badge { font-weight: bold; text-transform: uppercase; padding: 2px 5px; border-radius: 3px; }
        .status-accepted { color: green; background: #e8f5e9; }
        .status-rejected { color: red; background: #ffebee; }
    </style>
</head>
<body>
    <div style="text-align: right; margin-bottom: 20px;">
        Jakarta, {{ \Carbon\Carbon::parse($request->submitted_at)->format('d F Y') }}
    </div>

    <div class="content">
        Perihal: <strong>Pengunduran Diri</strong>
        <br><br>
        Kepada Yth,<br>
        <strong>HRD Manager</strong><br>
        PT SOBAT HR<br>
        di Tempat
    </div>

    <div class="content">
        <p class="paragraph">Dengan hormat,</p>
        <p class="paragraph">Saya yang bertanda tangan di bawah ini:</p>
        
        <div class="identity">
            <div class="row">
                <div class="label">Nama</div>
                <div class="sep">:</div>
                <div class="value">{{ $request->employee->full_name }}</div>
            </div>
            <div class="row">
                <div class="label">NIK</div>
                <div class="sep">:</div>
                <div class="value">{{ $request->employee->employee_number }}</div>
            </div>
            <div class="row">
                <div class="label">Jabatan</div>
                <div class="sep">:</div>
                <div class="value">{{ ucwords(str_replace('_', ' ', $request->employee->position ?? $request->employee->role->name ?? 'Staff')) }}</div>
            </div>
            <div class="row">
                <div class="label">Departemen</div>
                <div class="sep">:</div>
                <div class="value">{{ $request->employee->organization->name ?? '-' }}</div>
            </div>
        </div>

        <p class="paragraph">
            Melalui surat ini, saya bermaksud untuk mengajukan pengunduran diri dari jabatan saya sebagai 
            <strong>{{ ucwords(str_replace('_', ' ', $request->employee->position ?? 'Staff')) }}</strong> 
            di PT SOBAT HR.
        </p>

        <p class="paragraph">
            Sesuai dengan ketentuan yang berlaku, hari terakhir saya bekerja adalah pada tanggal 
            <strong>{{ $request->detail && $request->detail->last_working_date ? \Carbon\Carbon::parse($request->detail->last_working_date)->format('d F Y') : '-' }}</strong>.
        </p>

        <p class="paragraph">
            {{ $request->description }}
        </p>

        <p class="paragraph">
            Saya mengucapkan terima kasih yang sebesar-besarnya atas kesempatan dan pengalaman berharga yang telah diberikan selama saya bekerja di perusahaan ini. Saya juga memohon maaf apabila selama bekerja terdapat kesalahan atau kekeliruan yang saya lakukan.
        </p>

        <p class="paragraph">
            Saya berharap PT SOBAT HR semakin sukses dan berkembang di masa depan.
        </p>
    </div>

    <div class="footer">
        Hormat saya,
        <div class="signature-box">
            <!-- Digital Signature Placeholder or Name -->
            <br><br><br>
        </div>
        <strong>{{ $request->employee->full_name }}</strong>
    </div>

    <!-- Official Approval Record (Footer) -->
    <div class="approval-section">
        <div style="font-weight: bold; border-bottom: 1px dashed #ccc; padding-bottom: 5px; margin-bottom: 10px;">
            CATATAN INTERNAL PERUSAHAAN
        </div>
        <div>
            Status Pengajuan: 
            <span class="status-badge {{ $request->status == 'approved' ? 'status-accepted' : ($request->status == 'rejected' ? 'status-rejected' : '') }}">
                {{ strtoupper($request->status) }}
            </span>
        </div>
        <div style="margin-top: 5px;">
            ID Pengajuan: #REQ-{{ str_pad($request->id, 6, '0', STR_PAD_LEFT) }}
        </div>
        
        @if($request->approvals->isNotEmpty())
        <div style="margin-top: 10px;">
            <strong>Riwayat Persetujuan:</strong>
            <ul style="margin-top: 5px; padding-left: 20px;">
                @foreach($request->approvals as $approval)
                    <li>
                        {{ $approval->approver->full_name }} ({{ $approval->status }}) 
                        - {{ \Carbon\Carbon::parse($approval->updated_at)->format('d M Y') }}
                        @if($approval->note) <br><em>Note: {{ $approval->note }}</em> @endif
                    </li>
                @endforeach
            </ul>
        </div>
        @endif
    </div>
</body>
</html>
