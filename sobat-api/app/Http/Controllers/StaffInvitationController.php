<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\Invitation;
use App\Models\Organization;
use App\Models\Division;
use App\Models\Employee;
use App\Exports\InvitationsExport;
use Maatwebsite\Excel\Facades\Excel;

class StaffInvitationController extends Controller
{
    public function export()
    {
        return Excel::download(new InvitationsExport, 'pending_invitations.xlsx');
    }

    public function index(Request $request)
    {
        $invitations = Invitation::where('status', 'pending')
            ->with('organization')
            ->orderBy('created_at', 'desc')
            ->paginate(100);

        return response()->json($invitations);
    }

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls|max:10240',
        ]);

        set_time_limit(300); // 5 minutes max execution time

        $file = $request->file('file');
        $storedPath = $file->store('staff_imports', 'local');

        try {
            // Parse Excel file using maatwebsite/excel
            $data = Excel::toArray([], $file)[0];

            if (empty($data)) {
                return response()->json([
                    'error' => 'File is empty or could not be parsed.',
                ], 422);
            }

            $preview = [];
            $divisions = Division::all(); // Cache divisions for matching

            foreach ($data as $index => $row) {
                if ($index === 0)
                    continue; // Skip header

                // Convert encoding to UTF-8 for each cell
                $name = isset($row[0]) ? mb_convert_encoding($row[0], 'UTF-8', 'auto') : '';
                $email = isset($row[1]) ? mb_convert_encoding($row[1], 'UTF-8', 'auto') : '';
                $role = isset($row[2]) ? mb_convert_encoding($row[2], 'UTF-8', 'auto') : 'staff';
                $divisionInput = isset($row[3]) ? mb_convert_encoding($row[3], 'UTF-8', 'auto') : '';
                $jobLevel = isset($row[4]) ? mb_convert_encoding($row[4], 'UTF-8', 'auto') : '';
                $track = isset($row[5]) ? mb_convert_encoding($row[5], 'UTF-8', 'auto') : '';

                // Fuzzy Match Division
                $matchedDiv = $this->findDivision($divisionInput, $divisions);

                $rowData = [
                    'rowIndex' => $index + 1,
                    'name' => trim($name),
                    'email' => trim($email),
                    'role' => trim($role),
                    'division_input' => trim($divisionInput),
                    'job_level' => trim($jobLevel),
                    'track' => trim($track),
                    'track' => trim($track),
                    'division_id' => $matchedDiv ? $matchedDiv->id : null,
                    'organization_name' => $matchedDiv ? $matchedDiv->name : null,
                    // Legacy support
                    'organization_id' => null, 
                    'valid' => true,
                    'errors' => [],
                    'temporary_password' => null,
                ];

                $validator = Validator::make([
                    'name' => trim($name),
                    'email' => trim($email),
                    'division' => trim($divisionInput),
                ], [
                    'name' => 'required|string|max:255',
                    'email' => 'required|email|unique:users,email',
                    // 'division' => 'required', // Optional? Or required? Let's make it optional but warn if not found
                ], [
                    'email.unique' => 'Email sudah terdaftar di sistem',
                    'email.email' => 'Format email tidak valid',
                    'email.required' => 'Email wajib diisi',
                    'name.required' => 'Nama wajib diisi',
                ]);

                if ($validator->fails()) {
                    $rowData['valid'] = false;
                    $rowData['errors'] = $validator->errors()->all();
                } else {
                    if (!$matchedDiv && !empty($divisionInput)) {
                        $rowData['valid'] = false;
                        $rowData['errors'][] = "Divisi '$divisionInput' tidak ditemukan di Master Data.";
                    }
                    if (empty($divisionInput)) {
                        // Warning or Error? Let's assume default will be assigned or warning.
                        // For now let's allow empty but maybe warn? 
                        // User said "match excel with db", implies excel HAS division.
                        // $rowData['errors'][] = "Divisi wajib diisi.";
                    }

                    // Generate temporary password
                    $password = Str::random(12);
                    $rowData['temporary_password'] = $password;
                }

                $preview[] = $rowData;
            }

            return response()->json(['preview' => $preview]);

        } catch (\Maatwebsite\Excel\Exceptions\NoTypeDetectedException $e) {
            return response()->json([
                'error' => 'File format tidak didukung. Pastikan file adalah Excel (.xlsx atau .xls) yang valid.',
                'details' => $e->getMessage(),
            ], 422);
        } catch (\Exception $e) {
            // Handle encoding errors
            if (strpos($e->getMessage(), 'UTF-8') !== false || strpos($e->getMessage(), 'Malformed') !== false) {
                return response()->json([
                    'error' => 'File memiliki karakter yang tidak valid.',
                    'solution' => 'Silakan buka file di Excel, lalu Save As dengan memilih format "Excel Workbook (.xlsx)" dan pastikan tidak ada karakter khusus yang aneh.',
                    'details' => $e->getMessage(),
                ], 422);
            }

            return response()->json([
                'error' => 'Failed to parse file: ' . $e->getMessage(),
                'solution' => 'Pastikan file Excel Anda valid dan tidak corrupt.',
            ], 500);
        }
    }

    /**
     * Fuzzy search for Division
     */
    private function findDivision($input, $divisions)
    {
        if (empty($input))
            return null;

        $input = strtolower(trim($input));
        $bestMatch = null;
        $shortestDistance = -1;

        foreach ($divisions as $div) {
            $divName = strtolower($div->name);
            $divCode = $div->code ? strtolower($div->code) : '';

            // Exact match on Name or Code
            if ($divName === $input || $divCode === $input) {
                return $div;
            }

            // Levenshtein distance on Name only
            $distance = levenshtein($input, $divName);

            // Check if this is a better match
            // Allow distance up to 3 or 30% of string length
            $threshold = max(3, strlen($input) * 0.3);

            if ($distance <= $threshold) {
                if ($shortestDistance < 0 || $distance < $shortestDistance) {
                    $shortestDistance = $distance;
                    $bestMatch = $div;
                }
            }
        }

        return $bestMatch;
    }

    public function execute(Request $request)
    {
        \Illuminate\Support\Facades\Log::info('Execute invitation endpoint hit', ['payload' => $request->all()]);

        $request->validate([
            'rows' => 'required|array',
            'rows.*.name' => 'required|string',
            'rows.*.email' => 'required|email',
            'rows.*.role' => 'nullable|string',
            'rows.*.job_level' => 'nullable|string',
            'rows.*.track' => 'nullable|in:operational,office',
            'rows.*.division_id' => 'nullable|exists:divisions,id',
            'rows.*.organization_id' => 'nullable|exists:organizations,id',
        ]);

        $rows = $request->input('rows');
        $successCount = 0;
        $failedCount = 0;
        $errors = [];

        foreach ($rows as $row) {
            try {
                // Check if email already in Users OR Invitations
                if (\App\Models\User::where('email', $row['email'])->exists()) {
                    $failedCount++;
                    $errors[] = "Email {$row['email']} already registered as user";
                    continue;
                }

                // Check pending invitations
                $existingInvite = Invitation::where('email', $row['email'])
                    ->where('status', 'pending')
                    ->first();

                if ($existingInvite) {
                    $failedCount++;
                    $errors[] = "Email {$row['email']} already has pending invitation";
                    continue;
                }

                // Create Invitation Record
                $invite = Invitation::create([
                    'email' => $row['email'],
                    'name' => $row['name'],
                    'role' => $row['role'] ?? 'staff',
                    'division_id' => $row['division_id'] ?? null,
                    'organization_id' => $row['organization_id'] ?? null,
                    'token' => Str::random(32),
                    'status' => 'pending',
                    'payload' => json_encode($row),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                \Illuminate\Support\Facades\Log::info('Invitation created', ['id' => $invite->id, 'email' => $invite->email]);

                $successCount++;
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Invitation failed', ['email' => $row['email'], 'error' => $e->getMessage()]);
                $failedCount++;
                $errors[] = "Failed to invite {$row['email']}: " . $e->getMessage();
            }
        }

        return response()->json([
            'message' => "Successfully queued {$successCount} invitations.",
            'failed' => $failedCount,
            'errors' => $errors
        ]);
    }

    public function verifyToken($token)
    {
        $token = trim($token);
        $anyInvite = Invitation::where('token', $token)->with(['organization', 'division'])->first();

        if (!$anyInvite) {
            return response()->json(['valid' => false, 'message' => 'Token not found in database.'], 404);
        }

        if ($anyInvite->status !== 'pending') {
            return response()->json(['valid' => false, 'message' => "Token found but status is '{$anyInvite->status}'."], 400);
        }

        // Parse payload for extra details if any
        $payload = $anyInvite->payload ? (is_array($anyInvite->payload) ? $anyInvite->payload : json_decode($anyInvite->payload, true)) : [];

        return response()->json([
            'valid' => true,
            'name' => $anyInvite->name,
            'email' => $anyInvite->email,
            'organization' => $anyInvite->organization ? $anyInvite->organization->name : ($anyInvite->division ? $anyInvite->division->name : null),
            'division_id' => $anyInvite->division_id,
            'organization_id' => $anyInvite->organization_id,
            'job_level' => $payload['job_level'] ?? null,
            'track' => $payload['track'] ?? null,
            'role' => $anyInvite->role,
        ]);
    }

    public function accept(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
            'job_level' => 'nullable|string',
            'track' => 'nullable|in:operational,office',
            'organization_id' => 'nullable|exists:organizations,id',
            'division_id' => 'nullable|exists:divisions,id', // Added
            'division' => 'nullable|string',
            'role' => 'nullable|string',
        ]);

        $invitation = Invitation::where('token', $request->token)
            ->where('status', 'pending')
            ->first();

        if (!$invitation) {
            return response()->json(['message' => 'Invitation invalid or expired.'], 404);
        }

        \DB::beginTransaction();
        try {
            // 1. Get Default Role & Organization
            $roleName = $invitation->role ?: 'staff';
            $role = \App\Models\Role::where('name', $roleName)->first();
            if (!$role) {
                $role = \App\Models\Role::where('name', 'staff')->first();
            }

            // Organization fallback (Try to match division name to organization, or use ID 1)
            $orgId = $invitation->organization_id;
            $divId = $invitation->division_id;
            
            // If user selected a division (string), try to find matching Division model
            if ($request->has('division') && !$divId) {
                $div = Division::where('name', $request->division)->first();
                if ($div) {
                    $divId = $div->id;
                }
            }

            // If we have a division ID, we can get the department from it
            $divisionModel = null;
            if ($divId) {
                $divisionModel = Division::with('department')->find($divId);
            }

            if (!$orgId) {
                // Determine sensible default or fallback
                $org = Organization::first();
                $orgId = $org ? $org->id : 1;
            }

            // 2. Create User
            $user = \App\Models\User::create([
                'name' => $invitation->name,
                'email' => $invitation->email,
                'password' => \Illuminate\Support\Facades\Hash::make($request->password),
                'role_id' => $role ? $role->id : 1,
                'division' => $divisionModel ? $divisionModel->name : ($request->division ?? null), // Save division name
            ]);

            // 3. Create Employee Profile
            $payload = $invitation->payload ? (is_array($invitation->payload) ? $invitation->payload : json_decode($invitation->payload, true)) : [];
            
            // Allow override from Request if provided, otherwise fallback to Payload, then Defaults
            $jobLevel = $request->has('job_level') ? $request->job_level : ($payload['job_level'] ?? null);
            $track = $request->has('track') ? $request->track : ($payload['track'] ?? null);
            $finalOrgId = $request->has('organization_id') && $request->organization_id ? $request->organization_id : $orgId;
            $finalDivId = $request->has('division_id') && $request->division_id ? $request->division_id : $divId;
            $roleName = $request->has('role') ? $request->role : ($invitation->role ?: 'staff');

            // Re-fetch role if overridden
            $role = \App\Models\Role::where('name', $roleName)->first();
            if (!$role) {
                 $role = \App\Models\Role::where('name', 'staff')->first();
            }

            \App\Models\Employee::create([
                'user_id' => $user->id,
                'organization_id' => $finalOrgId,
                'employee_code' => 'EMP-' . str_pad($user->id, 4, '0', STR_PAD_LEFT),
                'full_name' => $user->name,
                'email' => $user->email,
                'position' => ucfirst($role ? $role->name : 'Staff'),
                'job_level' => $jobLevel,
                'track' => $track,
                'division_id' => $finalDivId, // Store Division ID
                'department' => $divisionModel && $divisionModel->department ? $divisionModel->department->name : ($request->division ?? null),
                'phone' => '-',
                'address' => '-',
                'join_date' => now(),
                'birth_date' => '1990-01-01',
                'basic_salary' => 0,
                'status' => 'active',
            ]);

            // 4. Update Invitation
            $invitation->update([
                'status' => 'accepted',
                'registered_at' => now(),
            ]);

            // 5. Generate Auth Token
            $token = $user->createToken('auth_token')->plainTextToken;

            \DB::commit();

            return response()->json([
                'message' => 'Account activated successfully.',
                'token' => $token,
                'user' => $user
            ]);

        } catch (\Exception $e) {
            \DB::rollBack();
            return response()->json(['message' => 'Failed to activate account: ' . $e->getMessage()], 500);
        }
    }
}
