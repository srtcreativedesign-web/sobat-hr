<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// Replace selectedDivision type
$content = str_replace(
    "const [selectedDivision, setSelectedDivision] = useState<'all' | 'office' | 'fnb' | 'minimarket' | 'reflexiology' | 'wrapping' | 'hans' | 'cellular' | 'money_changer'>('fnb');",
    "const [selectedDivision, setSelectedDivision] = useState<'all' | 'office' | 'fnb' | 'minimarket' | 'reflexiology' | 'wrapping' | 'hans' | 'cellular' | 'money_changer' | 'tungtau'>('fnb');",
    $content
);

// Add to dropdown options
$content = str_replace(
    '<option value="fnb">FnB</option>',
    '<option value="fnb">FnB</option>\n              <option value="tungtau">FnB Tungtau</option>',
    $content
);

// Endpoints
$content = str_replace("if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';", "if (selectedDivision === 'fnb') endpoint = '/payrolls/fnb';\n    if (selectedDivision === 'tungtau') endpoint = '/payrolls/tungtau';", $content);
$content = str_replace("if (selectedDivision === 'fnb') importEndpoint = '/payrolls/fnb/import';", "if (selectedDivision === 'fnb') importEndpoint = '/payrolls/fnb/import';\n    if (selectedDivision === 'tungtau') importEndpoint = '/payrolls/tungtau/import';", $content);
$content = str_replace("if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/\${pendingApprovalId}/status`;", "if (selectedDivision === 'fnb') endpoint = `/payrolls/fnb/\${pendingApprovalId}/status`;\n        if (selectedDivision === 'tungtau') endpoint = `/payrolls/tungtau/\${pendingApprovalId}/status`;", $content);
$content = str_replace("if (selectedDivision === 'fnb') saveEndpoint = '/payrolls/fnb/import/save';", "if (selectedDivision === 'fnb') saveEndpoint = '/payrolls/fnb/import/save';\n                            if (selectedDivision === 'tungtau') saveEndpoint = '/payrolls/tungtau/import/save';", $content);

// Arrays of divisions
$oldArray1 = "['fnb', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer']";
$newArray1 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer']";
$content = str_replace($oldArray1, $newArray1, $content);

$oldArray2 = "['fnb', 'minimarket', 'reflexiology', 'wrapping']";
$newArray2 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping']";
$content = str_replace($oldArray2, $newArray2, $content);

$oldArray3 = "['fnb', 'minimarket', 'reflexiology', 'hans', 'cellular', 'money_changer']";
$newArray3 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'hans', 'cellular', 'money_changer']";
$content = str_replace($oldArray3, $newArray3, $content);

$oldArray4 = "['fnb', 'minimarket', 'reflexiology', 'wrapping', 'hans']";
$newArray4 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping', 'hans']";
$content = str_replace($oldArray4, $newArray4, $content);

// Slip endpoint logic 1
$slipOld1 = "const endpoint = selectedDivision === 'fnb'\n                                  ? `/payrolls/fnb/\${payroll.id}/slip`";
$slipNew1 = "const endpoint = selectedDivision === 'tungtau'\n                                  ? `/payrolls/tungtau/\${payroll.id}/slip`\n                                  : selectedDivision === 'fnb'\n                                  ? `/payrolls/fnb/\${payroll.id}/slip`";
$content = str_replace($slipOld1, $slipNew1, $content);

// Slip endpoint logic 2
$slipOld2 = "const endpoint = selectedDivision === 'fnb'\n                          ? `/payrolls/fnb/\${selectedPayroll.id}/slip`";
$slipNew2 = "const endpoint = selectedDivision === 'tungtau'\n                          ? `/payrolls/tungtau/\${selectedPayroll.id}/slip`\n                          : selectedDivision === 'fnb'\n                          ? `/payrolls/fnb/\${selectedPayroll.id}/slip`";
$content = str_replace($slipOld2, $slipNew2, $content);

// Long IF conditions
$longIf1 = "(selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'hans' || selectedDivision === 'office' || selectedDivision === 'cellular' || selectedDivision === 'money_changer')";
$longIf1New = "(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'hans' || selectedDivision === 'office' || selectedDivision === 'cellular' || selectedDivision === 'money_changer')";
$content = str_replace($longIf1, $longIf1New, $content);

$longIf2 = "selectedDivision !== 'fnb' && selectedDivision !== 'minimarket' && selectedDivision !== 'reflexiology' && selectedDivision !== 'wrapping' && selectedDivision !== 'hans' && selectedDivision !== 'cellular' && selectedDivision !== 'money_changer'";
$longIf2New = "selectedDivision !== 'tungtau' && selectedDivision !== 'fnb' && selectedDivision !== 'minimarket' && selectedDivision !== 'reflexiology' && selectedDivision !== 'wrapping' && selectedDivision !== 'hans' && selectedDivision !== 'cellular' && selectedDivision !== 'money_changer'";
$content = str_replace($longIf2, $longIf2New, $content);

$longIf3 = "(selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping')";
$longIf3New = "(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping')";
$content = str_replace($longIf3, $longIf3New, $content);

file_put_contents($file, $content);
echo "Frontend patched successfully!";
