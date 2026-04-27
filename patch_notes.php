<?php
$controllers = glob(__DIR__ . '/sobat-api/app/Http/Controllers/Api/Payroll*Controller.php');
foreach ($controllers as $file) {
    $content = file_get_contents($file);
    
    // Add 'notes' => 'nullable|string' to validation
    if (!str_contains($content, "'notes' => 'nullable|string'")) {
        $content = preg_replace(
            "/'approval_signature'\s*=>\s*'nullable\|string',?\s*.*?\n/m",
            "\\0            'notes' => 'nullable|string',\n",
            $content
        );
    }
    
    // Add $data['notes'] = $request->notes;
    if (!str_contains($content, "\$data['notes'] = \$request->notes;")) {
        $content = preg_replace(
            "/\\\$data\['signer_name'\]\s*=\s*\\\$request->signer_name;\n/m",
            "\\0            \$data['notes'] = \$request->notes;\n",
            $content
        );
    }
    
    file_put_contents($file, $content);
}
echo "Done patching controllers\n";
