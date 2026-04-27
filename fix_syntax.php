<?php
$controllers = glob(__DIR__ . '/sobat-api/app/Http/Controllers/Api/Payroll*Controller.php');
foreach ($controllers as $file) {
    $content = file_get_contents($file);
    
    // Pattern that was created by the previous script:
    // 'approval_signature' => 'nullable|string', (maybe ])
    // ]); (if existed)
    // 'notes' => 'nullable|string',
    
    // Let's just cleanly remove the added notes and re-insert them correctly inside the array.
    $content = str_replace("'notes' => 'nullable|string',\n", "", $content);
    
    // Now cleanly insert it correctly
    // Look for 'approval_signature' => 'nullable|string'
    // and replace it with 'approval_signature' => 'nullable|string', \n            'notes' => 'nullable|string'
    $content = preg_replace(
        "/'approval_signature'\s*=>\s*'nullable\|string'([ \t]*)/m",
        "'approval_signature' => 'nullable|string',\n            'notes' => 'nullable|string'\$1",
        $content
    );
    
    file_put_contents($file, $content);
}
echo "Done fixing syntax\n";
