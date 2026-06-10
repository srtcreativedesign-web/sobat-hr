const fs = require('fs');

// Read Hans controller as base
let content = fs.readFileSync('sobat-api/app/Http/Controllers/Api/PayrollHansController.php', 'utf8');

// 1. Rename class
content = content.replace('class PayrollHansController extends Controller', 'class PayrollRetailController extends Controller');
content = content.replace('use App\\Models\\PayrollHans;', '');

// 2. Add getModel methods
const getModelCode = `
    private function isAdmin(): bool
    {
        $user = auth()->user();
        $roleName = $user->role ? strtolower($user->role->name) : '';
        return in_array($roleName, [Role::SUPER_ADMIN, Role::ADMIN, Role::ADMIN_CABANG, Role::HR]);
    }

    private function getModel($divisionType)
    {
        $models = [
            'cellular' => \\App\\Models\\PayrollCelluller::class,
            'hans' => \\App\\Models\\PayrollHans::class,
            'ref' => \\App\\Models\\PayrollRef::class,
            'wrapping' => \\App\\Models\\PayrollWrapping::class,
            'mm' => \\App\\Models\\PayrollMm::class,
            'money_changer' => \\App\\Models\\PayrollMoneyChanger::class,
        ];

        if (!isset($models[$divisionType])) {
            abort(400, "Invalid division_type: {$divisionType}");
        }

        return new $models[$divisionType];
    }
`;
content = content.replace('    use Traits\\PayrollThpCalculator;', '    use Traits\\PayrollThpCalculator;\n' + getModelCode);

// 3. Update index
content = content.replace(/PayrollHans::with/g, '$this->getModel($request->division_type)->with');
// We need to inject $request->validate(['division_type' => 'required']) into index, store, updateStatus, destroy, generateSlip
content = content.replace('public function index(Request $request)\n    {', "public function index(Request $request)\n    {\n        $request->validate(['division_type' => 'required']);\n");

// 4. Fix other method signatures
content = content.replace('public function show($id)', 'public function show(Request $request, $id)');
content = content.replace('PayrollHans::findOrFail', '$this->getModel($request->division_type)->findOrFail');
content = content.replace('public function generateSlip($id)', 'public function generateSlip(Request $request, $id)');
content = content.replace('public function destroy($id)', 'public function destroy(Request $request, $id)');

// 5. Update formatPayroll
content = content.replace('private function formatPayroll($payroll)', 'private function formatPayrollData($payroll)');
content = content.replace(/\$this->formatPayroll/g, '$this->formatPayrollData');

const oldFormat = `$formatted['allowances'] = [
             'Uang Makan' => [
                 'rate' => $payroll->meal_rate,
                 'amount' => $payroll->meal_amount,
             ],
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Kehadiran' => [
                 'rate' => $payroll->attendance_rate,
                 'amount' => $payroll->attendance_amount,
             ],
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Lembur' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Bonus' => $payroll->bonus,
             'Insentif' => $payroll->incentive,
             'THR' => $payroll->holiday_allowance,
             'Adj Kekurangan Gaji' => $payroll->adjustment, // New
             'Kebijakan HO' => $payroll->policy_ho,
        ];`;

const newFormat = `$formatted['allowances'] = [
             'Transport' => [
                 'rate' => $payroll->transport_rate,
                 'amount' => $payroll->transport_amount,
             ],
             'Kehadiran' => [
                 'rate' => $payroll->attendance_rate,
                 'amount' => $payroll->attendance_amount,
             ],
             'Tunjangan Kesehatan' => $payroll->health_allowance,
             'Tunjangan Jabatan' => $payroll->position_allowance,
             'Lembur' => [
                 'rate' => $payroll->overtime_rate,
                 'hours' => $payroll->overtime_hours,
                 'amount' => $payroll->overtime_amount,
             ],
             'Target Koli' => $payroll->target_koli ?? 0,
             'Fee Aksesoris' => $payroll->accessory_fee ?? 0,
             'Backup' => $payroll->backup ?? 0,
             'Insentif Kehadiran' => $payroll->insentif_kehadiran ?? 0,
             'Insentif Lebaran' => $payroll->holiday_allowance,
             'Adjustment' => $payroll->adjustment,
             'Kebijakan HO' => $payroll->policy_ho,
        ];`;

content = content.replace(oldFormat, newFormat);

const oldDed = `$formatted['deductions'] = [
            'Absen 1X' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late, 
            'Selisih SO' => $payroll->deduction_so_shortage, // New
            'Tidak Hadir' => $payroll->deduction_alpha,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];`;

const newDed = `$formatted['deductions'] = [
            'Potongan Absen' => $payroll->deduction_absent,
            'Terlambat' => $payroll->deduction_late, 
            'Selisih SO' => $payroll->deduction_shortage,
            'Pinjaman' => $payroll->deduction_loan,
            'Adm Bank' => $payroll->deduction_admin_fee,
            'BPJS TK' => $payroll->deduction_bpjs_tk,
        ];`;
        
content = content.replace(oldDed, newDed);

const oldThpParams = `['basic_salary', 'meal_amount', 'transport_amount', 'attendance_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'bonus', 'incentive', 'holiday_allowance', 'adjustment', 'policy_ho'],
            ['deduction_absent', 'deduction_late', 'deduction_so_shortage', 'deduction_alpha', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']`;
            
const newThpParams = `['basic_salary', 'attendance_amount', 'transport_amount', 'health_allowance', 'position_allowance', 'overtime_amount', 'target_koli', 'accessory_fee', 'backup', 'insentif_kehadiran', 'holiday_allowance', 'adjustment', 'policy_ho'],
            ['deduction_absent', 'deduction_late', 'deduction_shortage', 'deduction_loan', 'deduction_admin_fee', 'deduction_bpjs_tk']`;

content = content.replace(oldThpParams, newThpParams);

fs.writeFileSync('sobat-api/app/Http/Controllers/Api/PayrollRetailController.php', content);
console.log('Recreated PayrollRetailController!');
