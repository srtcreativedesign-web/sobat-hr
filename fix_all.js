const fs = require('fs');
let content = fs.readFileSync('/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollRetailController.php', 'utf8');

// 1. Remove the accidental injection in getModel
const accidentalStart = content.indexOf('$allHeaders = [];');
if (accidentalStart > -1 && accidentalStart < content.indexOf('abort(400')) {
    const accidentalEnd = content.indexOf('}', content.indexOf('$uiHeaders[$col] = trim($displayTitle);')) + 2;
    content = content.substring(0, accidentalStart) + content.substring(accidentalEnd);
}

// 2. Fix uiHeaders in parseHeaders (which is near the end)
const parseHeadersStart = content.lastIndexOf('public function parseHeaders');
if (parseHeadersStart > -1) {
    const oldHeadersStr = `            $allHeaders = [];
            $allSubs = [];
            $colOrder = [];
            
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                $allHeaders[$col] = $cell->getValue();
                $allSubs[$col] = $sheet->getCell($col . ($headerRowIndex + 1))->getValue();
            }`;
            
    const newHeadersStr = `            $allHeaders = [];
            $allSubs = [];
            $colOrder = [];
            $uiHeaders = [];
            
            $headerRow = $sheet->getRowIterator($headerRowIndex, $headerRowIndex)->current();
            $cellIterator = $headerRow->getCellIterator('A', $highestColumn);
            $cellIterator->setIterateOnlyExistingCells(false);
            
            foreach ($cellIterator as $cell) {
                $col = $cell->getColumn();
                $colOrder[] = $col;
                
                $headerValue = trim((string)$cell->getValue());
                $subValue = trim((string)$sheet->getCell($col . ($headerRowIndex + 1))->getValue());
                
                $allHeaders[$col] = $headerValue;
                $allSubs[$col] = $subValue;
                
                $displayTitle = $headerValue;
                if (empty($displayTitle)) {
                    for ($i = count($colOrder) - 1; $i >= 0; $i--) {
                        if (!empty($allHeaders[$colOrder[$i]])) {
                            $displayTitle = $allHeaders[$colOrder[$i]];
                            break;
                        }
                    }
                }
                
                if (!empty($subValue)) {
                    $displayTitle .= empty($displayTitle) ? $subValue : ' - ' . $subValue;
                }
                
                $uiHeaders[$col] = trim($displayTitle);
            }`;
            
    content = content.replace(oldHeadersStr, newHeadersStr);
    
    // Also fix the return
    const oldReturn = `'headers' => $allHeaders,`;
    const newReturn = `'headers' => $uiHeaders,`;
    // only replace the last occurrence which is in parseHeaders
    const lastReturnIndex = content.lastIndexOf(oldReturn);
    if (lastReturnIndex > -1) {
        content = content.substring(0, lastReturnIndex) + newReturn + content.substring(lastReturnIndex + oldReturn.length);
    }
}

// 3. Update formatPayrollData
content = content.replace(/'Target Koli' => \$payroll->target_koli \?\? 0,\s*'Fee Aksesoris' => \$payroll->accessory_fee \?\? 0,\s*'Insentif Lebaran'/g, "'Target Koli' => $payroll->target_koli ?? 0,\n                'Fee Aksesoris' => $payroll->accessory_fee ?? 0,\n                'Backup' => $payroll->backup ?? 0,\n                'Insentif Kehadiran' => $payroll->insentif_kehadiran ?? 0,\n                'Insentif Lebaran'");

// 4. Update calculateThp array
const oldThp = `['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'target_koli', 'accessory_fee', 'holiday_allowance', 'adjustment', 'policy_ho']`;
const newThp = `['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'target_koli', 'accessory_fee', 'backup', 'insentif_kehadiran', 'holiday_allowance', 'adjustment', 'policy_ho']`;
content = content.replace(oldThp, newThp);

fs.writeFileSync('/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollRetailController.php', content);
console.log('Fixed everything!');
