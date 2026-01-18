<?php

use App\Models\Employee;
use Illuminate\Support\Carbon;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$employee = Employee::first();
if (!$employee) {
    echo "No employee found.\n";
    exit;
}

echo "Employee ID: " . $employee->id . "\n";
echo "Join Date (Raw): " . $employee->getAttributes()['join_date'] . "\n";
echo "Join Date (Parsed): " . ($employee->join_date ? $employee->join_date->format('Y-m-d') : 'NULL') . "\n";
echo "Current Date: " . now()->format('Y-m-d') . "\n";

if ($employee->join_date) {
    $diff = $employee->join_date->diffInYears(now());
    echo "Diff In Years: " . $diff . "\n";
    
    if ($diff < 1) {
        echo "Status: Not Eligible (< 1 year)\n";
    } else {
        echo "Status: Eligible\n";
    
        // Check Requests
        $used = \App\Models\RequestModel::where('employee_id', $employee->id)
                ->where('type', 'leave')
                ->whereIn('status', ['pending', 'approved'])
                ->whereYear('start_date', now()->year)
                ->get();
                
        echo "Used Requests Count: " . $used->count() . "\n";
        $totalUsed = $used->sum('amount');
        echo "Total Used Amount: " . $totalUsed . "\n";
        
        $legacyUsed = $used->sum(function ($req) {
             if ($req->amount > 0) return $req->amount;
             if ($req->start_date && $req->end_date) {
                 return $req->start_date->diffInDays($req->end_date) + 1;
             }
             return 0;
        });
        echo "Total Used (Legacy Calc): " . $legacyUsed . "\n";
    }
} else {
    echo "Status: Join Date NULL\n";
}
