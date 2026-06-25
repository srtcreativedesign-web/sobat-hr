export interface Payroll {
  id: number;
  employee: {
    employee_code: string;
    full_name: string;
  };
  period_start: string;
  period_end: string;
  period?: string; // Sometimes available depending on endpoint
  basic_salary: number;
  allowances: any; // Allow object or number
  overtime_pay: number;
  deductions: any;
  total_deductions: number; // Added from backend calculation
  bpjs_health: number;
  bpjs_employment: number;
  tax: number;
  gross_salary: number;
  net_salary: number;
  details: any; // Flexible JSON
  status: 'draft' | 'pending' | 'approved' | 'paid';
  // FnB Specific Properties
  attendance?: Record<string, number>;
  ewa_amount?: number | string;
  approval_signature?: string;
  final_payment?: number; // Added for Cellular
  account_number?: string; // Added for detail display
  thp?: number | string; // Added for THP display
}
