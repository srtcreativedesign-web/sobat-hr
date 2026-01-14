<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\Invitation;
use App\Models\Organization;
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
            $organizations = Organization::all(); // Cache organizations for matching

            foreach ($data as $index => $row) {
                if ($index === 0)
                    continue; // Skip header

                // Convert encoding to UTF-8 for each cell
                $name = isset($row[0]) ? mb_convert_encoding($row[0], 'UTF-8', 'auto') : '';
                $email = isset($row[1]) ? mb_convert_encoding($row[1], 'UTF-8', 'auto') : '';
                $role = isset($row[2]) ? mb_convert_encoding($row[2], 'UTF-8', 'auto') : 'staff';
                $divisionInput = isset($row[3]) ? mb_convert_encoding($row[3], 'UTF-8', 'auto') : '';

                // Fuzzy Match Division
                $matchedOrg = $this->findOrganization($divisionInput, $organizations);

                $rowData = [
                    'rowIndex' => $index + 1,
                    'name' => trim($name),
                    'email' => trim($email),
                    'role' => trim($role),
                    'division_input' => trim($divisionInput),
                    'organization_id' => $matchedOrg ? $matchedOrg->id : null,
                    'organization_name' => $matchedOrg ? $matchedOrg->name : null,
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
                    if (!$matchedOrg && !empty($divisionInput)) {
                        $rowData['valid'] = false;
                        $rowData['errors'][] = "Divisi '$divisionInput' tidak ditemukan di sistem.";
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
     * Fuzzy search for organization
     */
    private function findOrganization($input, $organizations)
    {
        if (empty($input))
            return null;

        $input = strtolower(trim($input));
        $bestMatch = null;
        $shortestDistance = -1;

        foreach ($organizations as $org) {
            $orgName = strtolower($org->name);
            $orgCode = strtolower($org->code);

            // Exact match on Name or Code
            if ($orgName === $input || $orgCode === $input) {
                return $org;
            }

            // Levenshtein distance on Name only
            $distance = levenshtein($input, $orgName);

            // Check if this is a better match
            // Allow distance up to 3 or 30% of string length
            $threshold = max(3, strlen($input) * 0.3);

            if ($distance <= $threshold) {
                if ($shortestDistance < 0 || $distance < $shortestDistance) {
                    $shortestDistance = $distance;
                    $bestMatch = $org;
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
        $anyInvite = Invitation::where('token', $token)->with('organization')->first();

        if (!$anyInvite) {
            return response()->json(['valid' => false, 'message' => 'Token not found in database.'], 404);
        }

        if ($anyInvite->status !== 'pending') {
            return response()->json(['valid' => false, 'message' => "Token found but status is '{$anyInvite->status}'."], 400);
        }

        return response()->json([
            'valid' => true,
            'name' => $anyInvite->name,
            'email' => $anyInvite->email,
            'organization' => $anyInvite->organization ? $anyInvite->organization->name : null,
        ]);
    }

    public function accept(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
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

            // Organization fallback
            $orgId = $invitation->organization_id;
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
            ]);

            // 3. Create Employee Profile
            \App\Models\Employee::create([
                'user_id' => $user->id,
                'organization_id' => $orgId,
                'employee_code' => 'EMP-' . str_pad($user->id, 4, '0', STR_PAD_LEFT),
                'full_name' => $user->name,
                'email' => $user->email,
                'position' => ucfirst($role ? $role->name : 'Staff'),
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
