# SOBAT HR - API Documentation

## Base URL
```
http://localhost:8000/api
```

## Authentication
All protected endpoints require Bearer token authentication using Laravel Sanctum.

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

---

## Authentication Endpoints

### 1. Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "admin@sobat.co.id",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "1|xxxxxx",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "Super Admin",
    "email": "admin@sobat.co.id",
    "role": "super_admin"
  }
}
```

### 2. Register
**POST** `/auth/register`

**Request Body:**
```json
{
  "name": "New User",
  "email": "user@sobat.co.id",
  "password": "password123",
  "password_confirmation": "password123",
  "role_id": 4
}
```

### 3. Logout
**POST** `/auth/logout`
*Requires authentication*

### 4. Get Current User
**GET** `/auth/me`
*Requires authentication*

---

## Employee Endpoints

### 1. List Employees
**GET** `/employees`
*Requires authentication*

**Query Parameters:**
- `organization_id` (optional): Filter by organization
- `status` (optional): Filter by status (active, inactive, resigned)
- `search` (optional): Search by name or employee number

### 2. Get Employee Details
**GET** `/employees/{id}`
*Requires authentication*

### 3. Create Employee
**POST** `/employees`
*Requires authentication*

**Request Body:**
```json
{
  "user_id": 1,
  "organization_id": 1,
  "role_id": 4,
  "employee_number": "EMP006",
  "full_name": "New Employee",
  "email": "employee@sobat.co.id",
  "phone": "081234567890",
  "address": "Jakarta",
  "date_of_birth": "1990-01-01",
  "join_date": "2026-01-01",
  "position": "Staff",
  "department": "IT",
  "base_salary": 5000000,
  "status": "active",
  "contract_type": "permanent"
}
```

### 4. Update Employee
**PUT** `/employees/{id}`
*Requires authentication*

### 5. Delete Employee
**DELETE** `/employees/{id}`
*Requires authentication*

### 6. Get Employee Attendances
**GET** `/employees/{id}/attendances?month=1&year=2026`
*Requires authentication*

### 7. Get Employee Payrolls
**GET** `/employees/{id}/payrolls`
*Requires authentication*

---

## Organization Endpoints

### 1. List Organizations
**GET** `/organizations`
*Requires authentication*

### 2. Get Organization Details
**GET** `/organizations/{id}`
*Requires authentication*

### 3. Create Organization
**POST** `/organizations`
*Requires authentication*

**Request Body:**
```json
{
  "name": "New Branch",
  "code": "NBC",
  "type": "branch",
  "parent_id": 1,
  "address": "Address",
  "phone": "021-12345678",
  "email": "branch@sobat.co.id"
}
```

### 4. Update Organization
**PUT** `/organizations/{id}`
*Requires authentication*

### 5. Delete Organization
**DELETE** `/organizations/{id}`
*Requires authentication*

### 6. Get Organization Employees
**GET** `/organizations/{id}/employees`
*Requires authentication*

---

## Attendance Endpoints

### 1. List Attendances
**GET** `/attendances`
*Requires authentication*

**Query Parameters:**
- `employee_id` (optional)
- `date` (optional)
- `status` (optional): present, late, absent, leave, sick

### 2. Create Attendance
**POST** `/attendances`
*Requires authentication*

**Request Body:**
```json
{
  "employee_id": 1,
  "date": "2026-01-06",
  "check_in": "2026-01-06 09:00:00",
  "check_out": "2026-01-06 18:00:00",
  "status": "present",
  "notes": "On time"
}
```

### 3. Update Attendance
**PUT** `/attendances/{id}`
*Requires authentication*

### 4. Delete Attendance
**DELETE** `/attendances/{id}`
*Requires authentication*

### 5. Sync from Fingerprint Device
**POST** `/attendances/sync`
*Requires authentication*

**Request Body:**
```json
{
  "device_ip": "192.168.1.100",
  "date": "2026-01-06"
}
```

### 6. Get Monthly Report
**GET** `/attendances/report/{month}/{year}`
*Requires authentication*

Example: `/attendances/report/1/2026`

---

## Shift Endpoints

### 1. List Shifts
**GET** `/shifts?organization_id=1`
*Requires authentication*

### 2. Create Shift
**POST** `/shifts`
*Requires authentication*

**Request Body:**
```json
{
  "name": "Morning Shift",
  "organization_id": 1,
  "start_time": "08:00:00",
  "end_time": "17:00:00",
  "days": ["monday", "tuesday", "wednesday", "thursday", "friday"]
}
```

### 3. Update Shift
**PUT** `/shifts/{id}`
*Requires authentication*

### 4. Delete Shift
**DELETE** `/shifts/{id}`
*Requires authentication*

### 5. Assign Shift to Employees
**POST** `/shifts/assign`
*Requires authentication*

**Request Body:**
```json
{
  "shift_id": 1,
  "employee_ids": [4, 5]
}
```

---

## Request Endpoints (Cuti, Lembur, Reimburse, Resign)

### 1. List Requests
**GET** `/requests`
*Requires authentication*

**Query Parameters:**
- `employee_id` (optional)
- `type` (optional): leave, overtime, reimbursement, resignation
- `status` (optional): draft, pending, approved, rejected

### 2. Create Request
**POST** `/requests`
*Requires authentication*

**Request Body:**
```json
{
  "employee_id": 4,
  "type": "leave",
  "title": "Annual Leave",
  "description": "Need vacation",
  "start_date": "2026-02-01",
  "end_date": "2026-02-05"
}
```

### 3. Update Request
**PUT** `/requests/{id}`
*Requires authentication*
*Only allowed for draft status*

### 4. Delete Request
**DELETE** `/requests/{id}`
*Requires authentication*
*Only allowed for draft/rejected status*

### 5. Submit Request
**POST** `/requests/{id}/submit`
*Requires authentication*

### 6. Approve Request
**POST** `/requests/{id}/approve`
*Requires authentication*

**Request Body:**
```json
{
  "notes": "Approved"
}
```

### 7. Reject Request
**POST** `/requests/{id}/reject`
*Requires authentication*

**Request Body:**
```json
{
  "notes": "Reason for rejection"
}
```

---

## Approval Endpoints

### 1. Get All Approvals
**GET** `/approvals`
*Requires authentication*

### 2. Get Pending Approvals
**GET** `/approvals/pending`
*Requires authentication*

---

## Payroll Endpoints

### 1. List Payrolls
**GET** `/payrolls?employee_id=1&month=1&year=2026`
*Requires authentication*

### 2. Get Payroll Details
**GET** `/payrolls/{id}`
*Requires authentication*

### 3. Create Payroll
**POST** `/payrolls`
*Requires authentication*

### 4. Update Payroll
**PUT** `/payrolls/{id}`
*Requires authentication*

### 5. Delete Payroll
**DELETE** `/payrolls/{id}`
*Requires authentication*

### 6. Calculate Payroll
**POST** `/payrolls/calculate`
*Requires authentication*

**Request Body:**
```json
{
  "employee_id": 4,
  "period_month": 1,
  "period_year": 2026
}
```

### 7. Generate Payroll Slip (PDF)
**GET** `/payrolls/{id}/slip`
*Requires authentication*

### 8. Get Period Payrolls
**GET** `/payrolls/period/{month}/{year}`
*Requires authentication*

Example: `/payrolls/period/1/2026`

---

## Role Endpoints (Super Admin Only)

### 1. List Roles
**GET** `/roles`
*Requires authentication & super_admin role*

### 2. Create Role
**POST** `/roles`
*Requires authentication & super_admin role*

### 3. Update Role
**PUT** `/roles/{id}`
*Requires authentication & super_admin role*

### 4. Delete Role
**DELETE** `/roles/{id}`
*Requires authentication & super_admin role*

---

## Dashboard Endpoints

### 1. Get Analytics
**GET** `/dashboard/analytics`
*Requires authentication & super_admin/admin_cabang role*

**Response:**
```json
{
  "employees": {
    "total": 50,
    "active": 45,
    "inactive": 3,
    "resigned": 2
  },
  "attendance": {
    "present": 40,
    "late": 3,
    "absent": 2
  },
  "requests": {
    "pending": 5,
    "approved": 10,
    "rejected": 2
  },
  "contract_expiring_soon": 3
}
```

### 2. Get Turnover Rate
**GET** `/dashboard/turnover?year=2026`
*Requires authentication & super_admin/admin_cabang role*

### 3. Get Attendance Heatmap
**GET** `/dashboard/attendance-heatmap?month=1&year=2026`
*Requires authentication & super_admin/admin_cabang role*

---

## Error Responses

### 400 Bad Request
```json
{
  "message": "Validation error",
  "errors": {
    "email": ["The email field is required"]
  }
}
```

### 401 Unauthorized
```json
{
  "message": "Unauthenticated"
}
```

### 403 Forbidden
```json
{
  "message": "Unauthorized. Required role: super_admin"
}
```

### 404 Not Found
```json
{
  "message": "Resource not found"
}
```

### 422 Unprocessable Entity
```json
{
  "message": "Cannot update request that has been submitted"
}
```

---

## Default Credentials

After running seeders, use these credentials to login:

**Super Admin:**
- Email: `admin@sobat.co.id`
- Password: `password123`

**Admin Jakarta:**
- Email: `admin.jakarta@sobat.co.id`
- Password: `password123`

**Admin Surabaya:**
- Email: `admin.surabaya@sobat.co.id`
- Password: `password123`

**Staff:**
- Email: `john.doe@sobat.co.id`
- Password: `password123`

- Email: `jane.smith@sobat.co.id`
- Password: `password123`
