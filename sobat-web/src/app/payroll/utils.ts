// Helper to format currency
export const formatCurrency = (amount: number | string | undefined | null) => {
    const num = typeof amount === 'string' ? parseFloat(amount) : (amount || 0);
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(num || 0);
};

export const formatSmartValue = (amount: number, unit: string = '') => {
    if (amount === undefined || amount === null || isNaN(amount)) return '0';
    // If small value (assuming day/unit) and not 0, display as unit
    if (Math.abs(amount) < 1000 && amount !== 0) {
        return `${amount} ${unit}`;
    }
    return formatCurrency(amount);
};

export const getStatusBadge = (status: string) => {
    const styles = {
        pending: 'bg-yellow-100 text-yellow-700 border-yellow-200',
        approved: 'bg-blue-100 text-blue-700 border-blue-200',
        paid: 'bg-green-100 text-green-700 border-green-200',
        draft: 'bg-gray-100 text-gray-700 border-gray-200',
    };
    return styles[status as keyof typeof styles] || styles.pending;
};

// Helper to calculate total allowances for FnB/MM/Ref/Wrapping payroll
export const calculateTotalAllowances = (payroll: any, selectedDivision: string) => {
    if (['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        // FnB/MM/Ref backend returns structured allowances object
        if (payroll.allowances && typeof payroll.allowances === 'object') {
            const allowances = payroll.allowances;

            // Helper to parse value (handles both strings and numbers)
            const parseValue = (val: any) => {
                if (typeof val === 'object' && val?.amount !== undefined) {
                    return parseFloat(val.amount) || 0;
                }
                return parseFloat(val) || 0;
            };

            // Common keys plus new ones for MM
            return (
                parseValue(allowances['Kehadiran']) +
                parseValue(allowances['Transport']) +
                parseValue(allowances['Tunjangan Kesehatan']) +
                parseValue(allowances['Tunjangan Jabatan']) +
                // Exclude Lembur from Total Allowances if it's shown in its own column
                (selectedDivision === 'minimarket' || selectedDivision === 'fnb' || selectedDivision === 'wrapping' ? 0 : parseValue(allowances['Lembur'])) +
                parseValue(allowances['Insentif Lebaran'] || allowances['THR']) +
                parseValue(allowances['Adjustment']) +
                parseValue(allowances['Kebijakan HO']) +
                // MM specific
                parseValue(allowances['Uang Makan']) +
                parseValue(allowances['Bonus']) +
                parseValue(allowances['Insentif']) +
                // Wrapping specific
                parseValue(allowances['Target Koli']) +
                parseValue(allowances['Fee Aksesoris']) +
                parseValue(allowances['Adj BPJS']) +
                parseValue(allowances['Gaji Training']) +
                // Cellular specific
                parseValue(allowances['Lembur Wajib'])
            );
        }
        // Fallback to direct fields if structured object not available
        return (
            (parseFloat(payroll.attendance_amount) || 0) +
            (parseFloat(payroll.transport_amount) || 0) +
            (parseFloat(payroll.health_allowance) || 0) +
            (parseFloat(payroll.position_allowance) || 0) +
            // Exclude overtime_amount if shown separately
            (selectedDivision === 'minimarket' || selectedDivision === 'fnb' || selectedDivision === 'wrapping' ? 0 : (parseFloat(payroll.overtime_amount) || 0)) +
            (parseFloat(payroll.holiday_allowance) || 0) +
            (parseFloat(payroll.adjustment) || 0) +
            (parseFloat(payroll.policy_ho) || 0) +
            (parseFloat(payroll.meal_amount) || 0) +
            (parseFloat(payroll.bonus) || 0) +
            (parseFloat(payroll.incentive) || 0) +
            (parseFloat(payroll.target_koli) || 0) +
            (parseFloat(payroll.fee_aksesoris) || 0) +
            (parseFloat(payroll.adj_bpjs) || 0) +
            (parseFloat(payroll.training_salary) || 0) +
            (parseFloat(payroll.mandatory_overtime) || 0)
        );
    }
    // Generic payroll - allowances is a single number
    return parseFloat(payroll.allowances) || 0;
};

// Helper to calculate overtime pay for FnB/MM/Ref/Wrapping payroll
export const calculateOvertimePay = (payroll: any, selectedDivision: string) => {
    if (['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'wrapping', 'hans', 'cellular', 'money_changer'].includes(selectedDivision)) {
        // Check structured allowances first
        if (payroll.allowances?.Lembur) {
            const lembur = payroll.allowances.Lembur;
            let amount = 0;
            if (typeof lembur === 'object' && lembur.amount !== undefined) {
                amount += parseFloat(lembur.amount) || 0;
            } else {
                amount += parseFloat(lembur) || 0;
            }
            if (payroll.allowances['Lembur Wajib']) {
                const wajib = payroll.allowances['Lembur Wajib'];
                amount += parseFloat(typeof wajib === 'object' ? wajib.amount : wajib) || 0;
            }
            return amount;
        }
        return (parseFloat(payroll.overtime_amount) || 0) + (parseFloat(payroll.mandatory_overtime_amount) || 0);
    }
    return (parseFloat(payroll.overtime_pay) || 0) + (parseFloat(payroll.mandatory_overtime_amount) || 0);
};

// Helper to calculate total deductions for FnB/MM/Ref payroll
export const calculateTotalDeductions = (payroll: any, selectedDivision: string) => {
    let baseDeduction = 0;
    if (['minimarket', 'reflexiology', 'wrapping', 'hans', 'money_changer'].includes(selectedDivision)) {
        baseDeduction = parseFloat(payroll.deduction_total) || 0;
    } else if (selectedDivision === 'cellular') {
        baseDeduction = parseFloat(payroll.total_deduction) || 0;
    } else {
        // Generic / FnB
        baseDeduction = parseFloat(payroll.total_deductions) || 0;
    }
    return baseDeduction;
};

// Helper to calculate gross salary for FnB/MM/Ref/Wrapping payroll
export const calculateGrossSalary = (payroll: any, selectedDivision: string) => {
    if (selectedDivision === 'wrapping') {
        return parseFloat(payroll.total_salary_gross) || 0;
    }
    if (selectedDivision === 'cellular') {
        return parseFloat(payroll.gross_salary) || 0;
    }
    if (['fnb', 'tungtau', 'maximum', 'minimarket', 'reflexiology', 'hans', 'money_changer'].includes(selectedDivision)) {
        // For FnB/MM/Ref, use total_salary_2 which includes everything
        return parseFloat(payroll.total_salary_2) || 0;
    }
    return parseFloat(payroll.gross_salary) || 0;
};
