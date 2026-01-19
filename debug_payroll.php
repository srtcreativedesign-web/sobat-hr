<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';
$app = require_once __DIR__ . '/sobat-api/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Payroll;
use App\Http\Resources\PayrollResource;

$payrolls = Payroll::all();

foreach ($payrolls as $payroll) {
    $resource = new PayrollResource($payroll);
    $data = $resource->resolve(); // Turn into array
    
    echo "ID: " . $payroll->id . " | Employee: " . $payroll->employee->full_name . "\n";
    echo "Total Deductions (Raw): " . var_export($data['total_deductions'], true) . " (Type: " . gettype($data['total_deductions']) . ")\n";
    echo "Net Salary (Raw): " . var_export($data['net_salary'], true) . "\n";
    echo "Details: " . json_encode($payroll->details) . "\n";
    echo "--------------------------------\n";
}
