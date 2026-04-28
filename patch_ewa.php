<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-web/src/app/payroll/page.tsx';
$content = file_get_contents($file);

// Fix EWA block condition in modal
$content = str_replace(
    "{(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && selectedPayroll.ewa_amount && (",
    "{(selectedDivision === 'tungtau' || selectedDivision === 'fnb' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping') && parseFloat(selectedPayroll.ewa_amount) > 0 && (",
    $content
);

// Fix Cellular EWA condition in modal
$content = str_replace(
    "selectedDivision === 'cellular' && selectedPayroll.ewa_amount && (",
    "selectedDivision === 'cellular' && parseFloat(selectedPayroll.ewa_amount) > 0 && (",
    $content
);

// Fix ewa condition in table row
$content = str_replace(
    "{(selectedDivision === 'fnb' || selectedDivision === 'tungtau' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'cellular') && payroll.ewa_amount && (",
    "{(selectedDivision === 'fnb' || selectedDivision === 'tungtau' || selectedDivision === 'minimarket' || selectedDivision === 'reflexiology' || selectedDivision === 'wrapping' || selectedDivision === 'cellular') && parseFloat(payroll.ewa_amount) > 0 && (",
    $content
);

file_put_contents($file, $content);
echo "EWA conditions fixed!";
