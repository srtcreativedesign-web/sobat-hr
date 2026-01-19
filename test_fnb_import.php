<?php
// Test FnB Excel import directly via API simulation

require __DIR__ . '/sobat-api/vendor/autoload.php';

// Bootstrap Laravel
$app = require_once __DIR__ . '/sobat-api/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

echo "=== TESTING FnB PAYROLL IMPORT ===\n\n";

// Create a fake uploaded file
$file = new Illuminate\Http\UploadedFile(
    __DIR__ . '/format tabel payslip (3).xlsx',
    'format tabel payslip (3).xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    null,
    true // test mode
);

// Create request
$request = Illuminate\Http\Request::create('/api/payrolls/fnb/import', 'POST');
$request->files->set('file', $file);

// Get controller
$controller = new App\Http\Controllers\Api\PayrollFnbController();

try {
    echo "Calling import method...\n";
    $response = $controller->import($request);
    
    echo "\n=== RESPONSE ===\n";
    echo "Status: " . $response->status() . "\n";
    
    $data = json_decode($response->getContent(), true);
    
    if ($response->isSuccessful()) {
        echo "✅ Import successful!\n";
        echo "File: " . $data['file_name'] . "\n";
        echo "Rows: " . $data['rows_count'] . "\n\n";
        
        if ($data['rows_count'] > 0) {
            echo "=== FIRST ROW SAMPLE ===\n";
            $firstRow = $data['rows'][0];
            foreach ($firstRow as $key => $value) {
                if (is_numeric($value) && $value > 0) {
                    echo sprintf("  %-25s: %s\n", $key, number_format($value, 0, ',', '.'));
                } elseif ($value) {
                    echo sprintf("  %-25s: %s\n", $key, $value);
                }
            }
        }
    } else {
        echo "❌ Import failed\n";
        echo "Error: " . ($data['message'] ?? 'Unknown error') . "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
