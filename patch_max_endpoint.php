<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// 1. fetchPayrolls endpoint
$fetchSearch = "if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';";
$fetchReplace = "if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';\n      if (selectedDivision === 'maximum') endpoint = '/payrolls/maximum';";
$content = str_replace($fetchSearch, $fetchReplace, $content);

// 2. Single Approve endpoint
$approveSearch = "if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/\${pendingApprovalId}/status`;";
$approveReplace = "if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/\${pendingApprovalId}/status`;\n        if (selectedDivision === 'maximum') endpoint = `/payrolls/maximum/\${pendingApprovalId}/status`;";
$content = str_replace($approveSearch, $approveReplace, $content);

// 3. Download Slip endpoint in Table Action
$slipTableSearch = <<<EOT
                                const endpoint = selectedDivision === 'tungtau'
                                  ? `/payrolls/tungtau/\${payroll.id}/slip`
                                  : selectedDivision === 'fnb'
                                  ? `/payrolls/fnb/\${payroll.id}/slip`
EOT;
$slipTableReplace = <<<EOT
                                const endpoint = selectedDivision === 'maximum'
                                  ? `/payrolls/maximum/\${payroll.id}/slip`
                                  : selectedDivision === 'tungtau'
                                  ? `/payrolls/tungtau/\${payroll.id}/slip`
                                  : selectedDivision === 'fnb'
                                  ? `/payrolls/fnb/\${payroll.id}/slip`
EOT;
$content = str_replace($slipTableSearch, $slipTableReplace, $content);

// 4. Download Slip endpoint in Modal Action
$slipModalSearch = <<<EOT
                        const endpoint = selectedDivision === 'tungtau'
                          ? `/payrolls/tungtau/\${selectedPayroll.id}/slip`
                          : selectedDivision === 'fnb'
                          ? `/payrolls/fnb/\${selectedPayroll.id}/slip`
EOT;
$slipModalReplace = <<<EOT
                        const endpoint = selectedDivision === 'maximum'
                          ? `/payrolls/maximum/\${selectedPayroll.id}/slip`
                          : selectedDivision === 'tungtau'
                          ? `/payrolls/tungtau/\${selectedPayroll.id}/slip`
                          : selectedDivision === 'fnb'
                          ? `/payrolls/fnb/\${selectedPayroll.id}/slip`
EOT;
$content = str_replace($slipModalSearch, $slipModalReplace, $content);

// 5. Check if import endpoint is hardcoded?
$importEndpointSearch = "let endpoint = `/payrolls/import`;";
$importEndpointSearch2 = "if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/import/save`;";

if (strpos($content, $importEndpointSearch2) !== false) {
    $importEndpointReplace2 = "if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/import/save`;\n                        if (selectedDivision === 'maximum') endpoint = `/payrolls/maximum/import/save`;";
    $content = str_replace($importEndpointSearch2, $importEndpointReplace2, $content);
}

// 6. Check import URL
$uploadSearch = "if (selectedDivision === 'fnb') url = `/payrolls/fnb/import`;";
if (strpos($content, $uploadSearch) !== false) {
    $uploadReplace = "if (selectedDivision === 'fnb') url = `/payrolls/fnb/import`;\n      if (selectedDivision === 'maximum') url = `/payrolls/maximum/import`;";
    $content = str_replace($uploadSearch, $uploadReplace, $content);
}

file_put_contents($file, $content);
echo "Frontend endpoints patched.";
