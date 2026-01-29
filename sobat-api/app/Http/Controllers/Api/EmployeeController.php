<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;

class EmployeeController extends Controller
{
    /**
     * Display a listing of employees
     */
    public function index(Request $request)
    {
        $query = Employee::with(['user', 'organization', 'role']);

        // Filter by organization
        if ($request->has('organization_id')) {
            $query->where('organization_id', $request->organization_id);
        }

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Search by name or employee number
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                    ->orWhere('employee_code', 'like', "%{$search}%");
            });
        }

        $employees = $query->paginate(20);

        // Calculate Leave Balance for each employee
        foreach ($employees as $employee) {
            $employee->leave_balance = '-';

            if ($employee->join_date) {
                $yearsOfService = $employee->join_date->diffInYears(now());

                if ($yearsOfService >= 1) {
                    $quota = 12;

                    // Calculate used leave
                    $used = \App\Models\RequestModel::where('employee_id', $employee->id)
                        ->where('type', 'leave')
                        ->where('status', 'approved')
                        ->whereYear('start_date', now()->year)
                        ->get()
                        ->sum(function ($req) {
                            if ($req->amount > 0) return $req->amount;
                            if ($req->start_date && $req->end_date) {
                                return $req->start_date->diffInDays($req->end_date) + 1;
                            }
                            return 0; // fallback
                        });

                    $employee->leave_balance = max(0, $quota - $used) . ' / ' . $quota;
                }
            }
        }

        return response()->json($employees);
    }

    /**
     * Store a newly created employee
     */
    public function store(Request $request)
    {
        // Allow partial employee creation for mobile profile flow.
        // Keep `full_name` required but make other HR fields nullable so
        // the client can create/update progressively.
        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id',
            'organization_id' => 'nullable|exists:organizations,id',
            'role_id' => 'nullable|exists:roles,id',
            'employee_number' => 'nullable|string|unique:employees',
            'employee_code' => 'nullable|string|unique:employees',
            'full_name' => 'required|string|max:255',
            'email' => 'nullable|email|unique:employees',
            'phone' => 'nullable', // allow string or number
            'address' => 'nullable|string',
            'date_of_birth' => 'nullable|date',
            'join_date' => 'nullable|date',
            'position' => 'nullable|string',
            'department' => 'nullable|string',
            'base_salary' => 'nullable|numeric|min:0',
            'status' => 'nullable|in:active,inactive,resigned',
            'job_level' => 'nullable|string',
            'track' => 'nullable|in:operational,office',
            'contract_type' => 'nullable|in:permanent,contract,probation',
            'contract_end_date' => 'nullable|date',
            // Additional employee profile fields
            'place_of_birth' => 'nullable|string',
            'ktp_address' => 'nullable|string',
            'current_address' => 'nullable|string',
            'gender' => 'nullable|in:male,female',
            'religion' => 'nullable|string',
            'marital_status' => 'nullable|string',
            'ptkp_status' => 'nullable|string',
            'nik' => 'nullable|string',
            'npwp' => 'nullable|string',
            'bank_account_number' => 'nullable|string',
            'bank_account_name' => 'nullable|string',
            'father_name' => 'nullable|string',
            'mother_name' => 'nullable|string',
            'spouse_name' => 'nullable|string',
            'family_contact_number' => 'nullable', // allow string or number
            'education' => 'nullable', // Accept array/json or string
            'supervisor_name' => 'nullable|string',
            'supervisor_position' => 'nullable|string',
            'photo_path' => 'nullable|string',
        ]);

        // Map incoming keys to actual DB columns where names differ
        $data = [];
        if (isset($validated['user_id']))
            $data['user_id'] = $validated['user_id'];
        if (isset($validated['organization_id']))
            $data['organization_id'] = $validated['organization_id'];
        if (isset($validated['role_id']))
            $data['role_id'] = $validated['role_id'];
        // support both employee_number and employee_code from clients
        if (isset($validated['employee_number']))
            $data['employee_code'] = $validated['employee_number'];
        if (isset($validated['employee_code']))
            $data['employee_code'] = $validated['employee_code'];
        $data['full_name'] = $validated['full_name'];
        if (isset($validated['email']))
            $data['email'] = $validated['email'];
        if (isset($validated['phone']))
            $data['phone'] = $validated['phone'];
        if (isset($validated['address']))
            $data['address'] = $validated['address'];
        if (isset($validated['date_of_birth']))
            $data['birth_date'] = $validated['date_of_birth'];
        if (isset($validated['birth_date']))
            $data['birth_date'] = $validated['birth_date'];
        if (isset($validated['join_date']))
            $data['join_date'] = $validated['join_date'];
        if (isset($validated['position']))
            $data['position'] = $validated['position'];
        if (isset($validated['level']))
            $data['level'] = $validated['level'];
        if (isset($validated['base_salary']))
            $data['basic_salary'] = $validated['base_salary'];
        if (isset($validated['basic_salary']))
            $data['basic_salary'] = $validated['basic_salary'];
        if (isset($validated['contract_end_date']))
            $data['contract_end_date'] = $validated['contract_end_date'];
        if (isset($validated['contract_type']))
            $data['employment_status'] = $validated['contract_type'];
        if (isset($validated['employment_status']))
            $data['employment_status'] = $validated['employment_status'];
        if (isset($validated['status']))
            $data['status'] = $validated['status'];
        if (isset($validated['job_level']))
            $data['job_level'] = $validated['job_level'];
        if (isset($validated['track']))
            $data['track'] = $validated['track'];

        // New additional fields added by migration (same names)
        $extraFields = [
            'place_of_birth',
            'ktp_address',
            'current_address',
            'gender',
            'religion',
            'marital_status',
            'ptkp_status',
            'nik',
            'npwp',
            'bank_account_number',
            'bank_account_name',
            'father_name',
            'mother_name',
            'spouse_name',
            'family_contact_number',
            'education',
            'supervisor_name',
            'supervisor_position',
            'department',
            'photo_path'
        ];
        foreach ($extraFields as $f) {
            if (isset($validated[$f]))
                $data[$f] = $validated[$f];
        }

        // If user_id not provided, link created employee to the authenticated user when available
        if (empty($data['user_id'])) {
            $authUser = $request->user();
            if ($authUser) {
                $data['user_id'] = $authUser->id;
            }
        }

        // Ensure required non-null DB columns exist: generate an employee_code if missing
        if (empty($data['employee_code'])) {
            $authUser = $request->user();
            $uid = $data['user_id'] ?? ($authUser ? $authUser->id : null);
            $prefix = $uid ? ('EMP' . $uid . '-') : 'EMP-';
            $data['employee_code'] = $prefix . substr(uniqid(), -6);
        }

        // Default organization_id to first available organization if not set
        if (empty($data['organization_id'])) {
            $defaultOrg = \App\Models\Organization::first();
            if ($defaultOrg) {
                $data['organization_id'] = $defaultOrg->id;
            }
        }

        // Default required text fields to prevent MySQL errors
        if (empty($data['position'])) {
            $data['position'] = '-';
        }
        if (empty($data['join_date'])) {
            $data['join_date'] = now()->toDateString();
        }

        // Check if employee with same full_name already exists
        // If yes, update existing record instead of creating duplicate
        $existingEmployee = Employee::where('full_name', $data['full_name'])->first();

        if ($existingEmployee) {
            // Update existing employee
            $existingEmployee->update($data);
            return response()->json($existingEmployee, 200);
        } else {
            // Create new employee
            $employee = Employee::create($data);
            return response()->json($employee, 201);
        }
    }

    /**
     * Display the specified employee
     */
    public function show(string $id)
    {
        $employee = Employee::with(['user', 'organization', 'role', 'attendances', 'payrolls'])
            ->findOrFail($id);

        return response()->json($employee);
    }

    /**
     * Update the specified employee
     */
    public function update(Request $request, string $id)
    {
        $employee = Employee::findOrFail($id);

        // Fix for frontend sending existing photo_path string
        if ($request->has('photo_path') && !$request->hasFile('photo_path')) {
            $request->merge(['photo_path' => null]);
        }

        $validated = $request->validate([
            'organization_id' => 'sometimes|exists:organizations,id',
            'role_id' => 'sometimes|exists:roles,id',
            'employee_number' => 'sometimes|nullable|string|unique:employees,employee_code,' . $id,
            'employee_code' => 'sometimes|nullable|string|unique:employees,employee_code,' . $id,
            'full_name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:employees,email,' . $id,
            'phone' => 'nullable', // allow string or number
            'address' => 'nullable|string',
            'date_of_birth' => 'nullable|date',
            'join_date' => 'nullable|date',
            'position' => 'nullable',
            'level' => 'nullable',
            'department' => 'nullable',
            'base_salary' => 'sometimes|numeric|min:0',
            'basic_salary' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|in:active,inactive,resigned',
            'contract_type' => 'sometimes|in:permanent,contract,probation',
            'employment_status' => 'sometimes|in:permanent,contract,probation',
            'job_level' => 'nullable|string',
            'track' => 'nullable|in:operational,office',
            'contract_end_date' => 'nullable|date',
            // Additional employee profile fields
            'place_of_birth' => 'nullable|string',
            'ktp_address' => 'nullable|string',
            'current_address' => 'nullable|string',
            'gender' => 'nullable|in:male,female',
            'religion' => 'nullable|string',
            'marital_status' => 'nullable|string',
            'ptkp_status' => 'nullable|string',
            'nik' => 'nullable|string',
            'npwp' => 'nullable|string',
            'bank_account_number' => 'nullable|string',
            'bank_account_name' => 'nullable|string',
            'father_name' => 'nullable|string',
            'mother_name' => 'nullable|string',
            'spouse_name' => 'nullable|string',
            'family_contact_number' => 'nullable', // allow string or number
            'education' => 'nullable', // Accept array/json or string
            'supervisor_name' => 'nullable|string',
            'supervisor_position' => 'nullable|string',
            'photo_path' => 'nullable|image|max:2048', // 2MB Max
        ]);

        // Map validated to actual DB columns similar to store()
        $data = [];
        if (isset($validated['organization_id']))
            $data['organization_id'] = $validated['organization_id'];
        if (isset($validated['role_id']))
            $data['role_id'] = $validated['role_id'];
        if (isset($validated['employee_number']))
            $data['employee_code'] = $validated['employee_number'];
        if (isset($validated['employee_code']))
            $data['employee_code'] = $validated['employee_code'];
        if (isset($validated['full_name']))
            $data['full_name'] = $validated['full_name'];
        if (isset($validated['email']))
            $data['email'] = $validated['email'];
        if (isset($validated['phone']))
            $data['phone'] = $validated['phone'];
        if (isset($validated['address']))
            $data['address'] = $validated['address'];
        if (isset($validated['date_of_birth']))
            $data['birth_date'] = $validated['date_of_birth'];
        if (isset($validated['birth_date']))
            $data['birth_date'] = $validated['birth_date'];
        if (isset($validated['join_date'])) {
            $newDateInput = $validated['join_date'];
            $newDate = $newDateInput ? \Carbon\Carbon::parse($newDateInput)->format('Y-m-d') : null;
            $oldDate = $employee->join_date ? $employee->join_date->format('Y-m-d') : null;

            // Debug logging
            \Illuminate\Support\Facades\Log::info("Join Date Check: Old={$oldDate}, New={$newDate}, Input={$newDateInput}");

            // If date is changing
            if ($newDate !== $oldDate) {
                // If old date was null, this is the first set (count remains 0)
                // If old date was NOT null, this is an edit
                if ($oldDate !== null) {
                    if ($employee->join_date_edit_count >= 1) {
                        return response()->json([
                            'message' => 'Tanggal bergabung hanya dapat diubah satu kali.'
                        ], 422);
                    }
                    $data['join_date_edit_count'] = $employee->join_date_edit_count + 1;
                }
                $data['join_date'] = $newDate;
            }
        }
        
        if (isset($validated['position']))
            $data['position'] = $validated['position'];
        if (isset($validated['level']))
            $data['level'] = $validated['level'];
        if (isset($validated['base_salary']))
            $data['basic_salary'] = $validated['base_salary'];
        if (isset($validated['basic_salary']))
            $data['basic_salary'] = $validated['basic_salary'];
        if (isset($validated['contract_end_date']))
            $data['contract_end_date'] = $validated['contract_end_date'];
        if (isset($validated['contract_type']))
            $data['employment_status'] = $validated['contract_type'];
        if (isset($validated['employment_status']))
            $data['employment_status'] = $validated['employment_status'];
        if (isset($validated['status']))
            $data['status'] = $validated['status'];
        if (isset($validated['job_level']))
            $data['job_level'] = $validated['job_level'];
        if (isset($validated['track']))
            $data['track'] = $validated['track'];

        $extraFields = [
            'place_of_birth',
            'ktp_address',
            'current_address',
            'gender',
            'religion',
            'marital_status',
            'ptkp_status',
            'nik',
            'npwp',
            'bank_account_number',
            'bank_account_name',
            'father_name',
            'mother_name',
            'spouse_name',
            'family_contact_number',
            'education',
            'supervisor_name',
            'supervisor_position',
            'department',
            // 'photo_path' handled separately below
        ];
        foreach ($extraFields as $f) {
            if (isset($validated[$f]))
                $data[$f] = $validated[$f];
        }

        // Handle File Upload
        if ($request->hasFile('photo_path')) {
            $file = $request->file('photo_path');
            // Store details: public/avatars/FILENAME
            // URL will be storage/avatars/FILENAME
            $path = $file->store('avatars', 'public');
            
            // If replacing, maybe delete old? (Optional for now)
            if ($employee->photo_path) {
                // \Illuminate\Support\Facades\Storage::disk('public')->delete($employee->photo_path);
            }

            $data['photo_path'] = $path;
        }

        $employee->update($data);

        return response()->json($employee);
    }

    /**
     * Remove the specified employee
     */
    public function destroy(string $id)
    {
        $employee = Employee::findOrFail($id);
        $employee->delete();

        return response()->json(['message' => 'Employee deleted successfully']);
    }

    /**
     * Get employee attendances
     */
    public function attendances(string $id, Request $request)
    {
        $employee = Employee::findOrFail($id);

        $query = $employee->attendances();

        if ($request->has('month') && $request->has('year')) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        }

        $attendances = $query->orderBy('date', 'desc')->paginate(31);

        return response()->json($attendances);
    }

    /**
     * Get employee payrolls
     */
    public function payrolls(string $id, Request $request)
    {
        $employee = Employee::findOrFail($id);

        $payrolls = $employee->payrolls()
            ->orderBy('period_month', 'desc')
            ->orderBy('period_year', 'desc')
            ->paginate(12);

        return response()->json($payrolls);
    }

    /**
     * Get potential supervisor based on organization and job level hierarchy
     */
    public function getSupervisorCandidate(Request $request)
    {
        $organizationId = $request->query('organization_id');
        $jobLevel = $request->query('job_level');
        $track = $request->query('track');

        if (!$organizationId || !$jobLevel) {
            return response()->json([
                'success' => false,
                'message' => 'Organization ID and Job Level are required'
            ], 400);
        }

        // Hierarchy Definitions
        $officeHierarchy = [
            'staff' => 'team_leader',
            'team_leader' => 'spv',
            'spv' => 'deputy_manager',
            'deputy_manager' => 'manager',
            'manager' => 'director',
        ];

        $operationalHierarchy = [
            'crew' => 'crew_leader',
            'crew_leader' => 'spv',
            'spv' => 'manager_ops',
        ];

        $targetLevel = null;

        if ($track === 'operational') {
            $targetLevel = $operationalHierarchy[$jobLevel] ?? null;
        } else {
            // Default to office if track is mixed or not specified, check office map
            $targetLevel = $officeHierarchy[$jobLevel] ?? null;
        }

        if (!$targetLevel) {
            return response()->json([
                'success' => false,
                'message' => 'No supervisor level found for this position',
                'data' => null
            ]);
        }

        // Find employee in the same organization with the target level
        $supervisor = Employee::where('organization_id', $organizationId)
            ->where('job_level', $targetLevel)
            ->where('status', 'active') // Ensure active
            ->first();

        // If not found in same org, maybe check parent org? 
        // For now user said "divisi yang sama" (same division).

        if ($supervisor) {
            return response()->json([
                'success' => true,
                'data' => [
                    'name' => $supervisor->full_name,
                    'position' => $supervisor->position // This is the string position, not job_level
                ]
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'No supervisor found',
            'data' => null
        ]);
    }
    /**
     * Enroll face for recognition
     */
    public function enrollFace(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|max:10240', // Max 10MB
        ]);

        $user = $request->user();
        if (!$user->employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $file = $request->file('photo');
        $path = $file->store('face_enrollments', 'public');
        $fullPath = storage_path('app/public/' . $path);

        // Call Python script to detect face
        $scriptPath = base_path('python_scripts/detect_face.py');
        // Fix: Force Python to run in arm64 mode because XAMPP is x86_64 but pip libs are arm64
        $command = "/usr/bin/arch -arm64 /usr/bin/python3 " . escapeshellarg($scriptPath) . " " . escapeshellarg($fullPath) . " 2>&1";
        $output = shell_exec($command);
        $result = json_decode($output, true);

        if (!$result || (isset($result['status']) && $result['status'] === 'error')) {
            // Delete the file if validation fails
            \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
            return response()->json([
                'message' => 'Gagal memproses validasi wajah.',
                'error' => $result['message'] ?? 'Script Failure',
                'debug_output' => $output // Debug Info for User
            ], 500);
        }

        if ($result['face_count'] === 0) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
            return response()->json(['message' => 'Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.'], 422);
        }

        if ($result['face_count'] > 1) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
            return response()->json(['message' => 'Terdeteksi lebih dari satu wajah. Pastikan hanya Anda di dalam foto.'], 422);
        }

        // Save path to employee record
        $user->employee->face_photo_path = $path;
        $user->employee->save();

        return response()->json([
            'message' => 'Wajah berhasil didaftarkan.',
            'face_photo_path' => $path
        ]);
    }

}
