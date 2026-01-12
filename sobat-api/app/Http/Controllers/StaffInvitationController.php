<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\Invitation;
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
        $invitations = \App\Models\Invitation::where('status', 'pending')
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
            foreach ($data as $index => $row) {
                if ($index === 0)
                    continue; // Skip header

                // Convert encoding to UTF-8 for each cell
                $name = isset($row[0]) ? mb_convert_encoding($row[0], 'UTF-8', 'auto') : '';
                $email = isset($row[1]) ? mb_convert_encoding($row[1], 'UTF-8', 'auto') : '';

                $rowData = [
                    'rowIndex' => $index + 1,
                    'name' => trim($name),
                    'email' => trim($email),
                    'valid' => true,
                    'errors' => [],
                    'temporary_password' => null,
                ];

                $validator = Validator::make([
                    'name' => trim($name),
                    'email' => trim($email),
                ], [
                    'name' => 'required|string|max:255',
                    'email' => 'required|email|unique:users,email',
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

    public function execute(Request $request)
    {
        \Illuminate\Support\Facades\Log::info('Execute invitation endpoint hit', ['payload' => $request->all()]);

        $request->validate([
            'rows' => 'required|array',
            'rows.*.name' => 'required|string',
            'rows.*.email' => 'required|email',
            // 'rows.*.temporary_password' => 'required|string', // Not mandatory for invitation table
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
                $existingInvite = \App\Models\Invitation::where('email', $row['email'])
                    ->where('status', 'pending')
                    ->first();

                if ($existingInvite) {
                    $failedCount++;
                    $errors[] = "Email {$row['email']} already has pending invitation";
                    continue;
                }

                // Create Invitation Record
                $invite = \App\Models\Invitation::create([
                    'email' => $row['email'],
                    'name' => $row['name'],
                    'token' => Str::random(32), // Unique token for registration link
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

        \Illuminate\Support\Facades\Log::info('Execute invitation finished', ['success' => $successCount, 'failed' => $failedCount]);

        return response()->json([
            'message' => "Successfully queued {$successCount} invitations.",
            'failed' => $failedCount,
            'errors' => $errors
        ]);
    }

    public function verifyToken($token)
    {
        $token = trim($token);

        // DEBUG: First check if token exists AT ALL
        $anyInvite = Invitation::where('token', $token)->first();

        if (!$anyInvite) {
            \Illuminate\Support\Facades\Log::warning('Token completely not found', ['token' => $token]);
            return response()->json(['valid' => false, 'message' => 'Token not found in database.'], 404);
        }

        // DEBUG: Check status
        if ($anyInvite->status !== 'pending') {
            \Illuminate\Support\Facades\Log::warning('Token found but status not pending', ['status' => $anyInvite->status]);
            return response()->json(['valid' => false, 'message' => "Token found but status is '{$anyInvite->status}' (expected 'pending')."], 400);
        }

        return response()->json([
            'valid' => true,
            'name' => $anyInvite->name,
            'email' => $anyInvite->email,
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
            $role = \App\Models\Role::where('name', 'staff')->first();
            $org = \App\Models\Organization::first(); // Fallback to first org

            // 2. Create User
            $user = \App\Models\User::create([
                'name' => $invitation->name,
                // 'username' => explode('@', $invitation->email)[0], // removed as username is not in fillable
                'email' => $invitation->email,
                'password' => \Illuminate\Support\Facades\Hash::make($request->password),
                'role_id' => $role ? $role->id : 1, // Fallback ID 1
            ]);

            // 3. Create Employee Profile
            \App\Models\Employee::create([
                'user_id' => $user->id,
                'organization_id' => $org ? $org->id : 1,
                'employee_code' => 'EMP-' . str_pad($user->id, 4, '0', STR_PAD_LEFT),
                'full_name' => $user->name, // Added full_name
                'email' => $user->email, // Added email
                'position' => 'Staff', // Default position
                'phone' => '-', // Default placeholder
                'address' => '-', // Default placeholder
                'join_date' => now(), // Fixed typo from joined_date
                'birth_date' => '1990-01-01', // Default placeholder
                'basic_salary' => 0, // Default placeholder
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
