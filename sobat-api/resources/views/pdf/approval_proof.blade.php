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
        @if($request->type == 'business_trip' && $request->businessTripDetail)
        <tr>
            <th>Destination</th>
            <td>{{ $request->businessTripDetail->destination }}</td>
        </tr>
        <tr>
            <th>Dates</th>
            <td>{{ $request->businessTripDetail->start_date->format('d M Y') }} - {{ $request->businessTripDetail->end_date->format('d M Y') }}</td>
        </tr>
        @endif
        @if($request->amount)
        <tr>
            <th>Amount / Duration</th>
            <td>{{ $request->amount }}</td>
        </tr>
        @endif
    </table>

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
                        // Check for Admin Override Name in Note
                        if ($approval->note && preg_match('/Approved by[:\s]+(.*)/i', $approval->note, $matches)) {
                             $extractedName = trim($matches[1]);
                             if (strtolower($extractedName) !== 'system/user') {
                                 $approverName = $extractedName;
                             }
                        }
                    @endphp
                    {{ $approverName }}<br>
                    <small>
                        @php
                            $jobLevel = $approval->approver->job_level ?? '';
                            $position = $approval->approver->position ?? '';
                            $displayPosition = !empty($jobLevel) ? str_replace('_', ' ', $jobLevel) : $position;
                            if (empty($displayPosition)) $displayPosition = 'Staff';
                        @endphp
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
    
    <div style="margin-top: 50px; text-align: center; font-size: 10px; color: #888;">
        This document is system generated by SOBAT-HR.
    </div>
</body>
</html>
