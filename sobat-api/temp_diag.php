<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$u = App\Models\User::find(8);
if (!$u) {
    echo 'USER 8 NOT FOUND' . PHP_EOL;
    exit;
}

echo 'USER 8: Name=' . $u->name . ' | Role=' . $u->role . ' | EmpID=' . ($u->employee_id ?? 'NULL') . PHP_EOL;

if ($u->employee_id) {
    $count = App\Models\Payroll::where('employee_id', $u->employee_id)->count();
    echo 'PAYROLLS FOR EMP ' . $u->employee_id . ': ' . $count . PHP_EOL;
} else {
    echo 'USER 8 HAS NO EMP ID LINKED' . PHP_EOL;
}

echo '--- RECENT PAYROLLS ---' . PHP_EOL;
$payrolls = App\Models\Payroll::with('employee')->latest()->take(10)->get();
foreach ($payrolls as $p) {
    echo 'ID=' . $p->id . ' | Period=' . $p->period . ' | EmpID=' . $p->employee_id . ' | Name=' . ($p->employee->full_name ?? 'Unk') . ' | Status=' . $p->status . PHP_EOL;
}
