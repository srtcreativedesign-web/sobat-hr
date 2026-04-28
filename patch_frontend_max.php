<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// 1. Add to dropdown
$content = str_replace(
    "<option value=\"tungtau\">FnB Tungtau</option>",
    "<option value=\"tungtau\">FnB Tungtau</option>\n            <option value=\"maximum\">FnB Maximum 600</option>",
    $content
);

// 2. Add to calculateGrossSalary
$content = str_replace(
    "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'hans', 'cellular', 'money_changer']",
    "['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'hans', 'cellular', 'money_changer']",
    $content
);

// 3. Add to ewa conditional block
$content = str_replace(
    "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping']",
    "['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping']",
    $content
);

$content = str_replace(
    "(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping')",
    "(selectedDivision === 'tungtau' || selectedDivision === 'maximum' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping')",
    $content
);

$content = str_replace(
    "(selectedDivision === 'fnb' || selectedDivision === 'tungtau' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'cellular')",
    "(selectedDivision === 'fnb' || selectedDivision === 'tungtau' || selectedDivision === 'maximum' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'cellular')",
    $content
);

file_put_contents($file, $content);
echo "Frontend patched.";
