<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

function checkModel($modelClass, $name) {
    if (!class_exists($modelClass)) return;
    try {
        $records = $modelClass::whereRaw('ewa_amount > 0')->limit(5)->get();
        if (count($records) > 0) {
            echo "Found " . count($records) . " records in $name with ewa_amount > 0\n";
            foreach($records as $rec) {
                echo "ID {$rec->id} ({$rec->period}): thp={$rec->thp}, ewa={$rec->ewa_amount}, net={$rec->net_salary}, grand_total=" . ($rec->grand_total ?? 'N/A') . "\n";
            }
        }
    } catch(\Exception $e) {}
}

$models = glob(__DIR__.'/app/Models/Payroll*.php');
foreach ($models as $modelFile) {
    $className = basename($modelFile, '.php');
    $fullClass = "\\App\\Models\\$className";
    checkModel($fullClass, $className);
}
