<?php
require __DIR__ . '/sobat-api/vendor/autoload.php';
use App\Http\Controllers\Api\PayrollFnbController;

$controller = new PayrollFnbController();
// It's hard to instantiate and call import directly without a Request.
