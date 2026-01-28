// User & Authentication Types
export interface User {
  id: number;
  name: string;
  email: string;
  role: Role | string;
  role_id: number;
  employee?: Employee;
  created_at?: string;
  updated_at?: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

// Employee Types
export interface Employee {
  id: number;
  user_id?: number;
  organization_id: number;
  role_id: number;
  shift_id?: number;
  employee_number: string;
  full_name: string;
  email: string;
  phone: string;
  address?: string;
  date_of_birth: string;
  join_date: string;
  position: string;
  department: string;
  base_salary: number;
  status: 'active' | 'inactive' | 'resigned';
  contract_type: 'permanent' | 'contract' | 'probation';
  contract_end_date?: string;
  user?: User;
  organization?: Organization;
  role?: Role;
  shift?: Shift;
  created_at?: string;
  updated_at?: string;
}

// Organization Types
export interface Organization {
  id: number;
  name: string;
  code: string;
  type: 'headquarters' | 'branch' | 'department';
  parent_id?: number;
  address?: string;
  phone?: string;
  email?: string;
  parent_organization?: Organization;
  child_organizations?: Organization[];
  created_at?: string;
  updated_at?: string;
}

// Role Types
export interface Role {
  id: number;
  name: string;
  display_name: string;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

// Attendance Types
export interface Attendance {
  id: number;
  employee_id: number;
  date: string;
  check_in: string;
  check_out?: string;
  work_hours?: number;
  status: 'present' | 'late' | 'absent' | 'leave' | 'sick';
  notes?: string;
  employee?: Employee;
  created_at?: string;
  updated_at?: string;
}

// Shift Types
export interface Shift {
  id: number;
  name: string;
  organization_id: number;
  start_time: string;
  end_time: string;
  days: string[];
  organization?: Organization;
  created_at?: string;
  updated_at?: string;
}

// Request Types
export interface Request {
  id: number;
  employee_id: number;
  type: 'leave' | 'overtime' | 'reimbursement' | 'resignation' | 'business_trip' | 'sick_leave' | 'asset';
  title: string;
  description: string;
  start_date?: string;
  end_date?: string;
  amount?: number;
  status: 'draft' | 'pending' | 'approved' | 'rejected' | 'cancelled';
  step_now?: number;
  submitted_at?: string;
  attachments?: string[] | string; // Flexible for JSON string or array
  detail?: any; // Flexible for dynamic details (like asset brand, spec)
  employee?: Employee;
  approvals?: Approval[];
  created_at?: string;
  updated_at?: string;
}

// Approval Types
export interface Approval {
  id: number;
  approvable_type?: string;
  approvable_id?: number;
  request_id?: number; // Backward compatibility or alias
  approver_id: number;
  level: number;
  status: 'pending' | 'approved' | 'rejected';
  note?: string; // Standardized to note (singular)
  notes?: string; // Backward compatibility
  acted_at?: string;
  approved_at?: string; // Backward compatibility
  request?: Request; // Alias for approvable if loaded
  approvable?: Request; // Polymorphic relation loaded correctly
  approver?: Employee;
  created_at?: string;
  updated_at?: string;
}

// Payroll Types
export interface Payroll {
  id: number;
  employee_id: number;
  period_month: number;
  period_year: number;
  base_salary: number;
  allowances: number;
  overtime_pay: number;
  deductions: number;
  bpjs_health: number;
  bpjs_employment: number;
  tax_pph21: number;
  net_salary: number;
  status: 'draft' | 'approved' | 'paid';
  paid_at?: string;
  employee?: Employee;
  created_at?: string;
  updated_at?: string;
}

// Dashboard Types
export interface DashboardAnalytics {
  employees: {
    total: number;
    active: number;
    inactive: number;
    resigned: number;
  };
  attendance: {
    present?: number;
    late?: number;
    absent?: number;
    leave?: number;
    sick?: number;
  };
  requests: {
    pending: number;
    approved: number;
    rejected: number;
  };
  contract_expiring_soon: number;
  period: {
    month: number;
    year: number;
  };
}

// Pagination Types
export interface PaginationMeta {
  current_page: number;
  from: number;
  last_page: number;
  per_page: number;
  to: number;
  total: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  links: {
    first: string;
    last: string;
    prev: string | null;
    next: string | null;
  };
  meta: PaginationMeta;
}

// API Response Types
export interface ApiError {
  message: string;
  errors?: Record<string, string[]>;
}
