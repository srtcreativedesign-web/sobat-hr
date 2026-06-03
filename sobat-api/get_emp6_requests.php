<?php
define('LARAVEL_START', microtime(true));
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\RequestModel;

// Employee ID 6
$query = RequestModel::with(['employee.division', 'approvals']);
$query->where('employee_id', 6);
$requests = $query->orderBy('created_at', 'desc')->paginate(20);

echo json_encode($requests, JSON_PRETTY_PRINT);
