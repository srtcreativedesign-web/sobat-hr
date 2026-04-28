<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// Fix array includes
$arr1 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer']";
$arr1_new = "['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer']";
$content = str_replace($arr1, $arr1_new, $content);

$arr2 = "['fnb', 'tungtau', 'minimarket', 'reflexiology', 'wrapping', 'hans']";
$arr2_new = "['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans']";
$content = str_replace($arr2, $arr2_new, $content);

// Fix deduction condition
$cond1 = "(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'hans' || selectedDivision === 'office' || selectedDivision === 'cellular' || selectedDivision === 'money_changer')";
$cond1_new = "(selectedDivision === 'tungtau' || selectedDivision === 'maximum' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'hans' || selectedDivision === 'office' || selectedDivision === 'cellular' || selectedDivision === 'money_changer')";
$content = str_replace($cond1, $cond1_new, $content);

file_put_contents($file, $content);
echo "UI conditions fixed.";
