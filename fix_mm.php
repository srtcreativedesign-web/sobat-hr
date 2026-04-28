<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollMmController.php';
$content = file_get_contents($file);

$fallbackSearch = <<<EOT
                // Fallback for grand total and net salary if header is missing (like in 04. Gaji Bekal.xlsx format)
                if (!\$parsed['grand_total'] || !\$parsed['net_salary']) {
                    // Try to guess from the last column if it contains a formula for total
                    \$guessedGrandTotal = \$getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex(\$highestColIndex), \$row);
                    \$guessedNet = \$getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex(\$highestColIndex), \$row);
EOT;

$fallbackReplace = <<<EOT
                // Hardcode specific columns for MM (AK = Grand Total/THP, AL = EWA, AM = Net Salary) if missing
                if (!\$parsed['ewa_amount']) {
                    \$valAL = \$getCellValue('AL', \$row);
                    if (is_numeric(\$valAL)) \$parsed['ewa_amount'] = (float)\$valAL;
                }
                if (!\$parsed['grand_total']) {
                    \$valAK = \$getCellValue('AK', \$row);
                    if (is_numeric(\$valAK)) \$parsed['grand_total'] = (float)\$valAK;
                }
                if (!\$parsed['net_salary']) {
                    \$valAM = \$getCellValue('AM', \$row);
                    if (is_numeric(\$valAM)) \$parsed['net_salary'] = (float)\$valAM;
                }

                // Recalculate THP universally just in case
                \$parsed['thp'] = \$parsed['net_salary'] + \$parsed['ewa_amount'];

                // Fallback for grand total and net salary if header is missing (like in 04. Gaji Bekal.xlsx format)
                if (!\$parsed['grand_total'] || !\$parsed['net_salary']) {
                    // Try to guess from the last column if it contains a formula for total
                    \$guessedGrandTotal = \$getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex(\$highestColIndex), \$row);
                    \$guessedNet = \$getCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex(\$highestColIndex), \$row);
EOT;

$content = str_replace($fallbackSearch, $fallbackReplace, $content);

file_put_contents($file, $content);
echo "PayrollMmController fixed for missing headers.\n";
