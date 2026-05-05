<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\PayrollMm;
use App\Models\PayrollFnb;
use App\Models\PayrollReflexiology;

function fixRecords($modelClass, $name) {
    $records = $modelClass::whereRaw('ewa_amount > 0 AND ewa_amount = net_salary')->get();
    echo "Found " . count($records) . " records in $name where ewa_amount == net_salary\n";
    foreach($records as $rec) {
        echo "ID {$rec->id} ({$rec->period}): thp={$rec->thp}, ewa={$rec->ewa_amount}, net={$rec->net_salary}, total_salary_1={$rec->total_salary_1}\n";
        // Fix: ewa_amount was wrongly assigned net_salary. Set ewa_amount = 0.
        // Recalculate THP: thp should just be net_salary if ewa is 0.
        $rec->ewa_amount = 0;
        $rec->thp = $rec->net_salary;
        $rec->save();
        echo " -> Fixed: ewa=0, thp={$rec->thp}\n";
    }
}

fixRecords(PayrollMm::class, 'MM');
fixRecords(PayrollFnb::class, 'FNB');
fixRecords(PayrollReflexiology::class, 'REF');
