<?php

use App\Models\Employee;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$staffs = Employee::whereIn('job_level', ['staff', 'crew'])->limit(5)->get();

echo "Checking explicit hierarchy matches for first 5 staff/crew:\n\n";

foreach ($staffs as $staff) {
    echo "Employee: {$staff->full_name} ({$staff->job_level}) - Dept: {$staff->department}\n";
    
    // Check for Manager in same Dept
    $managers = Employee::where('department', $staff->department)
                ->whereIn('job_level', ['manager', 'manager_divisi', 'spv'])
                ->get();
    
    if ($managers->count() > 0) {
        echo "✅ Found Managers/SPV in {$staff->department}:\n";
        foreach ($managers as $mgr) {
            echo "   - {$mgr->full_name} ({$mgr->job_level})\n";
        }
    } else {
        echo "❌ No Manager/SPV found in {$staff->department}!\n";
        
        // Suggest potential managers (loose match)
        $potential = Employee::where('department', 'LIKE', "%{$staff->department}%")
                    ->whereIn('job_level', ['manager', 'manager_divisi'])
                    ->get();
        if ($potential->count() > 0) {
            echo "   (But found similar dept matches):\n";
             foreach ($potential as $mgr) {
                echo "   - {$mgr->full_name} ({$mgr->job_level}) - Dept: {$mgr->department}\n";
            }
        }
    }
    echo "---------------------------------------------------\n";
}

echo "\nCheck specific 'Reimbursement' logic:\n";
// No specific logic for reimbursement differently than others in Controller
