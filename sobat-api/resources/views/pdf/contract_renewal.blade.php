<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Perpanjangan Kontrak Kerja</title>
    <style>
        body {
            font-family: "Times New Roman", Times, serif;
            font-size: 12pt;
            line-height: 1.5;
            margin: 2cm;
        }
        h1 {
            text-align: center;
            font-size: 16pt;
            font-weight: bold;
            text-decoration: underline;
            margin-bottom: 30px;
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .content {
            text-align: justify;
        }
        .party {
            margin-bottom: 20px;
        }
        .party-name {
            font-weight: bold;
        }
        .signatures {
            margin-top: 50px;
            width: 100%;
        }
        .signature-block {
            width: 45%;
            display: inline-block;
            text-align: center;
            vertical-align: top;
        }
        .signature-line {
            margin-top: 80px;
            border-top: 1px solid black;
            width: 80%;
            margin-left: auto;
            margin-right: auto;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>PERJANJIAN PERPANJANGAN KONTRAK KERJA</h1>
        <p>Nomor: {{ $contractNumber }}</p>
    </div>

    <div class="content">
        <p>Pada hari ini, {{ $dayName }}, tanggal {{ $dateDay }} bulan {{ $dateMonth }} tahun {{ $dateYear }}, yang bertanda tangan di bawah ini:</p>

        <div class="party">
            <p>1. <span class="party-name">PT. SOBAT KULINER INDONESIA</span>, berkedudukan di Jakarta, dalam hal ini diwakili oleh HRD Manager, selanjutnya disebut sebagai <strong>PIHAK PERTAMA</strong>.</p>
        </div>

        <div class="party">
            <p>2. <span class="party-name">{{ $employee->full_name }}</span>, NIK: {{ $employee->employee_code ?? '-' }}, Jabatan: {{ $employee->position }}, Alamat: {{ $employee->ktp_address ?? '-' }}, selanjutnya disebut sebagai <strong>PIHAK KEDUA</strong>.</p>
        </div>

        <p>PIHAK PERTAMA dan PIHAK KEDUA secara bersama-sama sepakat untuk mengadakan Perpanjangan Kontrak Kerja dengan ketentuan sebagai berikut:</p>

        <ol>
            <li>
                <p>Jangka waktu kontrak kerja diperpanjang selama <strong>{{ $durationMonths }} Bulan</strong>, terhitung mulai tanggal <strong>{{ $startDate }}</strong> sampai dengan tanggal <strong>{{ $endDate }}</strong>.</p>
            </li>
            <li>
                <p>Jabatan PIHAK KEDUA adalah sebagai <strong>{{ $employee->position }}</strong> pada Divisi <strong>{{ $employee->organization->name ?? '-' }}</strong>.</p>
            </li>
            <li>
                <p>Hak dan kewajiban masing-masing pihak tetap mengacu pada Peraturan Perusahaan yang berlaku.</p>
            </li>
            <li>
                <p>Hal-hal lain yang belum tercantum dalam perjanjian ini akan diatur kemudian.</p>
            </li>
        </ol>

        <p>Demikian Perjanjian Perpanjangan Kontrak Kerja ini dibuat dan ditandatangani oleh kedua belah pihak dalam keadaan sadar dan tanpa paksaan dari pihak manapun.</p>
    </div>

    <div class="signatures">
        <div class="signature-block">
            <p><strong>PIHAK PERTAMA</strong></p>
            <div class="signature-line"></div>
            <p>HRD Manager</p>
        </div>
        <div class="signature-block">
            <p><strong>PIHAK KEDUA</strong></p>
            <div class="signature-line"></div>
            <p>{{ $employee->full_name }}</p>
        </div>
    </div>
</body>
</html>
