<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tables = [
    'payrolls_mm' => 'ewa_amount',
    'payroll_fnb' => 'ewa_amount',
    'payrolls_ref' => 'ewa_amount',
    'payroll_tungtau' => 'ewa_amount',
    'payroll_maximums' => 'stafbook_loan', // The difference!
    'payrolls_wrapping' => 'ewa_amount',
    'payrolls_hans' => 'ewa_amount',
    'payrolls_money_changer' => 'ewa_amount',
    'payroll_cellullers' => 'ewa_amount',
];

use Illuminate\Support\Facades\DB;

foreach ($tables as $table => $ewa_col) {
    try {
        $count = DB::table($table)->whereRaw("$ewa_col > 0 AND $ewa_col = net_salary")->count();
        if ($count > 0) {
            DB::table($table)->whereRaw("$ewa_col > 0 AND $ewa_col = net_salary")->update([
                $ewa_col => 0
            ]);
            echo "Fixed $count rows in $table\n";
        } else {
            echo "No rows to fix in $table\n";
        }
    } catch (\Exception $e) {
        echo "Error in $table: " . $e->getMessage() . "\n";
    }
}
