<!DOCTYPE html>
<html>
<head>
    <title>Approval Proof</title>
    <style>
        body { font-family: sans-serif; font-size: 12px; }
        .header { text-align: center; margin-bottom: 20px; }
        .title { font-size: 18px; font-weight: bold; margin-bottom: 5px; }
        .subtitle { color: #666; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f5f5f5; }
        .success { color: green; font-weight: bold; }
        .signature-img { max-height: 50px; max-width: 100px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">APPROVAL PROOF</div>
        <div class="subtitle">Generated on {{ now()->format('d M Y H:i') }}</div>
    </div>

    <h3>Request Details</h3>
    <table>
        <tr>
            <th width="150">Request No</th>
            <td>REQ-{{ str_pad($request->id, 5, '0', STR_PAD_LEFT) }}</td>
        </tr>
        <tr>
            <th>Requester</th>
            <td>{{ $request->employee->full_name ?? 'Unknown' }}</td>
        </tr>
        <tr>
            <th>Type</th>
            <td>{{ ucfirst(str_replace('_', ' ', $request->type)) }}</td>
        </tr>
        <tr>
            <th>Submitted Date</th>
            <td>{{ $request->created_at->format('d M Y') }}</td>
        </tr>
        <tr>
            <th>Title / Description</th>
            <td>
                <strong>{{ $request->title }}</strong><br>
                {{ $request->description }}
            </td>
        </tr>
        <!-- Dynamic Details based on Type -->
        @if($request->exitPermitDetail)
        <tr>
            <th>Keperluan</th>
            <td>{{ ucfirst($request->exitPermitDetail->permit_type) }}</td>
        </tr>
        <tr>
            <th>Tujuan</th>
            <td>{{ $request->exitPermitDetail->destination }}</td>
        </tr>
        <tr>
            <th>No Polisi Kendaraan</th>
            <td>{{ $request->exitPermitDetail->vehicle_plate ?? '-' }}</td>
        </tr>
        <tr>
            <th>Tanggal</th>
            <td>{{ \Carbon\Carbon::parse($request->exitPermitDetail->date)->format('d M Y') }}</td>
        </tr>
        <tr>
            <th>Waktu (Keluar - Selesai)</th>
            <td>{{ \Carbon\Carbon::parse($request->exitPermitDetail->start_time)->format('H:i') }} - {{ $request->exitPermitDetail->end_time ? \Carbon\Carbon::parse($request->exitPermitDetail->end_time)->format('H:i') : 'Selesai' }}</td>
        </tr>
        @endif
    </table>

    <!-- Pemohon Signature -->
    @if($request->exitPermitDetail && $request->exitPermitDetail->signature)
    <div style="margin-bottom: 20px;">
        <h3>Tanda Tangan Pemohon</h3>
        <table style="width: 300px; border: none;">
            <tr>
                <td style="border: 1px solid #ddd; text-align: center; padding: 10px;">
                    <img src="{{ $request->exitPermitDetail->signature }}" style="max-height: 80px; max-width: 200px;">
                    <br><br>
                    <strong>{{ $request->employee->full_name ?? 'Pemohon' }}</strong>
                </td>
            </tr>
        </table>
    </div>
    @endif

    <div style="page-break-inside: avoid;">
    <h3>Approval Timeline</h3>
    <table>
        <thead>
            <tr>
                <th>Level</th>
                <th>Approver</th>
                <th>Status</th>
                <th>Date</th>
                <th>Signature</th>
            </tr>
        </thead>
        <tbody>
            @foreach($request->approvals as $approval)
            <tr>
                <td>Level {{ $approval->level }}</td>
                <td>
                    @php
                        $approverName = $approval->approver->full_name ?? 'Unknown';
                        $jobLevel = $approval->approver->job_level ?? '';
                        $position = $approval->approver->position ?? '';
                        $displayPosition = !empty($jobLevel) ? str_replace('_', ' ', $jobLevel) : $position;
                        if (empty($displayPosition)) $displayPosition = 'Staff';

                        // Check for Admin Override Name in Note
                        if ($approval->note && preg_match('/Approved by[:\s]+(.*)/i', $approval->note, $matches)) {
                             $extractedName = trim($matches[1]);
                             if (strtolower($extractedName) !== 'system/user') {
                                 $approverName = $extractedName;
                                 $displayPosition = 'HRD'; // Force HRD if overridden by admin
                             }
                        }
                    @endphp
                    {{ $approverName }}<br>
                    <small>
                        {{ ucwords($displayPosition) }}
                    </small>
                </td>
                <td class="{{ $approval->status == 'approved' ? 'success' : '' }}">
                    {{ ucfirst($approval->status) }}
                </td>
                <td>
                    {{ $approval->acted_at ? \Carbon\Carbon::parse($approval->acted_at)->format('d M Y H:i') : '-' }}
                </td>
                <td>
                    @php
                        $sig = $approval->signature;
                        if (!empty($sig) && !str_contains($sig, 'data:image')) {
                            $sig = 'data:image/png;base64,' . $sig;
                        }
                    @endphp
                    @if(!empty($sig) && str_contains($sig, 'data:image'))
                        <img src="{{ $sig }}" class="signature-img">
                    @elseif($approval->status == 'approved')
                        <span style="color:#aaa; font-style:italic;">Digital Signed (System)</span>
                    @else
                        -
                    @endif
                    @if($approval->note && strtolower($approval->note) !== 'approved by system/user')
                        <br><small>Note: {{ $approval->note }}</small>
                    @endif
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
    </div>
    
    @php
        $attachments = [];
        if (!empty($request->attachments)) {
            $reqAtt = is_string($request->attachments) ? json_decode($request->attachments, true) : $request->attachments;
            if (is_array($reqAtt)) {
                foreach($reqAtt as $a) {
                    $attachments[] = $a;
                }
            }
        }
        if ($request->type == 'overtime' && !empty($request->overtimeDetail->proof_image_done)) {
            $proofs = is_string($request->overtimeDetail->proof_image_done) ? json_decode($request->overtimeDetail->proof_image_done, true) : $request->overtimeDetail->proof_image_done;
            if (is_array($proofs)) {
                foreach($proofs as $p) {
                    $attachments[] = $p;
                }
            }
        }
    @endphp

    @if(count($attachments) > 0)
    <div style="margin-top: 30px;">
        <h3 style="margin-bottom: 15px;">Attachments / Evidence</h3>
        <table style="width: 100%; border: none; margin: 0; padding: 0;">
            <tr>
            @php $colCount = 0; @endphp
            @foreach($attachments as $path)
                @php
                    $base64 = '';
                    if (str_starts_with($path, 'data:image')) {
                        $base64 = $path;
                    } else {
                        $fullPath = storage_path('app/public/' . $path);
                        if (file_exists($fullPath)) {
                            $type = pathinfo($fullPath, PATHINFO_EXTENSION);
                            if (in_array(strtolower($type), ['jpg', 'jpeg', 'png', 'gif'])) {
                                $data = file_get_contents($fullPath);
                                $base64 = 'data:image/' . $type . ';base64,' . base64_encode($data);
                            }
                        }
                    }
                @endphp
                @if($base64)
                    <td style="width: 50%; padding: 5px; text-align: left; border: none; vertical-align: top;">
                        <img src="{{ $base64 }}" style="max-width: 100%; max-height: 200px; border: 1px solid #ddd; border-radius: 4px;">
                    </td>
                    @php 
                        $colCount++; 
                        if ($colCount % 2 == 0) {
                            echo '</tr><tr>';
                        }
                    @endphp
                @endif
            @endforeach
            </tr>
        </table>
    </div>
    @endif
    
    <div style="margin-top: 50px; text-align: center; font-size: 10px; color: #888;">
        This document is system generated by SOBAT-HR.
    </div>
</body>
</html>
