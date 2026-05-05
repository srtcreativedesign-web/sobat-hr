<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\PayrollMm;
use App\Models\PayrollFnb;
use App\Models\PayrollRef;

function fixRecords($modelClass, $name) {
    // Some floating point issues might exist, so check roughly
    $records = $modelClass::whereRaw('ewa_amount > 0 AND abs(ewa_amount - net_salary) < 100')->get();
    echo "Found " . count($records) . " records in $name where ewa_amount == net_salary\n";
    foreach($records as $rec) {
        echo "ID {$rec->id} ({$rec->period}): thp={$rec->thp}, ewa={$rec->ewa_amount}, net={$rec->net_salary}, grand_total={$rec->grand_total}\n";
        $rec->ewa_amount = 0;
        $rec->thp = $rec->net_salary;
        $rec->save();
        echo " -> Fixed: ewa=0, thp={$rec->thp}\n";
    }
}

fixRecords(PayrollMm::class, 'MM');
fixRecords(PayrollFnb::class, 'FNB');
fixRecords(PayrollRef::class, 'REF');
