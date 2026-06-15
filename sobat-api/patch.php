<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Http/Controllers/Api/PayrollRetailController.php';
$content = file_get_contents($file);

$search = <<<EOD
                \$isOvertimeHoursMapped = !empty(\$columnMapping['overtime_hours']);
                // FORCE: If hours are mapped AND are zero, amount MUST be zero, no matter what Excel says
                if (\$isOvertimeHoursMapped && \$overtimeHours <= 0) {
                    \$overtimeAmount = 0;
                } elseif (\$overtimeAmount <= 0 && \$overtimeRate > 0 && \$overtimeHours > 0) {
                    // Fallback: Calculate overtime amount from rate × hours if amount not mapped
                    \$overtimeAmount = \$overtimeRate * \$overtimeHours;
                }
                
                \$isAttendanceMapped = !empty(\$columnMapping['days_present']) || !empty(\$columnMapping['days_total']);
                // FORCE: If attendance is mapped AND days present are zero, mandatory amount MUST be zero
                if (\$isAttendanceMapped && \$daysPresent <= 0) {
                    \$mandatoryOvertimeAmount = 0;
                } elseif (\$mandatoryOvertimeAmount <= 0 && \$mandatoryOvertimeRate > 0 && \$daysPresent > 0) {
                    // Fallback: Calculate mandatory overtime amount from rate × days_present if amount not mapped
                    \$mandatoryOvertimeAmount = \$mandatoryOvertimeRate * \$daysPresent;
                }
EOD;

$replace = <<<EOD
                // Fallback: Calculate overtime amount from rate × hours if amount not mapped or was deduped
                if (\$overtimeAmount <= 0 && \$overtimeRate > 0 && \$overtimeHours > 0) {
                    \$overtimeAmount = \$overtimeRate * \$overtimeHours;
                }
                
                // Fallback: Calculate mandatory overtime amount from rate × days_present if amount not mapped or was deduped
                if (\$mandatoryOvertimeAmount <= 0 && \$mandatoryOvertimeRate > 0 && \$daysPresent > 0) {
                    \$mandatoryOvertimeAmount = \$mandatoryOvertimeRate * \$daysPresent;
                }
EOD;

if (strpos($content, $search) !== false) {
    file_put_contents($file, str_replace($search, $replace, $content));
    echo "Patch applied successfully.\n";
} else {
    echo "Search string not found.\n";
}
