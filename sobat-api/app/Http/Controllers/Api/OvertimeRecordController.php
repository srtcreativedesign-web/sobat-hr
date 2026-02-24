<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\OvertimeRecord;
use App\Models\RequestModel;
use Carbon\Carbon;

class OvertimeRecordController extends Controller
{
    public function index(Request $request)
    {
        $query = OvertimeRecord::with('employee.organization');

        if ($request->has('organization_id')) {
            $orgId = $request->organization_id;
            $query->whereHas('employee', function ($q) use ($orgId) {
                $q->where('organization_id', $orgId);
            });
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('employee', function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('employee_code', 'like', "%{$search}%");
            });
        }

        if ($request->has('month') && $request->has('year')) {
            $query->whereMonth('date', $request->month)
                  ->whereYear('date', $request->year);
        }

        return response()->json($query->orderBy('date', 'desc')->paginate(20));
    }

    public function backfill()
    {
        $requests = RequestModel::with('overtimeDetail')
            ->where('type', 'overtime')
            ->where('status', 'approved')
            ->get();

        $count = 0;
        foreach ($requests as $req) {
            if (!$req->overtimeDetail) continue;

            OvertimeRecord::updateOrCreate(
                ['request_id' => $req->id],
                [
                    'employee_id' => $req->employee_id,
                    'date' => $req->start_date,
                    'start_time' => $req->overtimeDetail->start_time,
                    'end_time' => $req->overtimeDetail->end_time,
                    'duration' => $req->overtimeDetail->duration,
                    'reason' => $req->reason,
                    'approved_at' => $req->updated_at, // Approximate
                ]
            );
            $count++;
        }

        return response()->json(['message' => "Backfilled {$count} records"]);
    }
}
