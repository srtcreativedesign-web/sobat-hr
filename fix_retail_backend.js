const fs = require('fs');
const path = './sobat-api/app/Http/Controllers/Api/PayrollRetailController.php';
let content = fs.readFileSync(path, 'utf8');

const oldAllowances = `'Target Koli' => $payroll->target_koli ?? 0,
                'Fee Aksesoris' => $payroll->accessory_fee ?? 0,
                'Insentif Lebaran' => $payroll->holiday_allowance,
                'Adjustment' => $payroll->adjustment,
                'Kebijakan HO' => $payroll->policy_ho,
            ];`;

const newAllowances = `'Target Koli' => $payroll->target_koli ?? 0,
                'Fee Aksesoris' => $payroll->accessory_fee ?? 0,
                'Backup' => $payroll->backup ?? 0,
                'Insentif Kehadiran' => $payroll->insentif_kehadiran ?? 0,
                'Insentif Lebaran' => $payroll->holiday_allowance,
                'Adjustment' => $payroll->adjustment,
                'Kebijakan HO' => $payroll->policy_ho,
            ];`;

content = content.replace(oldAllowances, newAllowances);

// Replace it twice since formatPayrollData might be duplicated in index and show? Let's check:
content = content.replace(oldAllowances, newAllowances); // Just in case.

const oldThpParams = `['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'target_koli', 'accessory_fee', 'holiday_allowance', 'adjustment', 'policy_ho']`;

const newThpParams = `['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'target_koli', 'accessory_fee', 'backup', 'insentif_kehadiran', 'holiday_allowance', 'adjustment', 'policy_ho']`;

content = content.replace(new RegExp(oldThpParams.replace(/[.*+?^$()|[\\]\\\\]/g, '\\\\$&'), 'g'), newThpParams);

fs.writeFileSync(path, content);
console.log('Backend allowances updated');
