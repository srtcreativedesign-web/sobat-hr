<?php
$files = glob(__DIR__ . '/sobat-api/resources/views/payslips/*.blade.php');
$notesBlock = <<<HTML
    @if(!empty(\$payroll->notes))
        <div style="margin-top: 15px; border-top: 1px dashed #ccc; padding-top: 10px;">
            <strong style="color: #333; font-size: 11px;">Catatan / Notes:</strong>
            <div style="font-style: italic; color: #555; font-size: 11px; margin-top: 4px;">{{ \$payroll->notes }}</div>
        </div>
    @endif
    
    <div class="signature-section">
HTML;

foreach ($files as $file) {
    $content = file_get_contents($file);
    if (!str_contains($content, '$payroll->notes')) {
        $content = str_replace('<div class="signature-section">', $notesBlock, $content);
        file_put_contents($file, $content);
    }
}
echo "Done patching PDF views\n";
