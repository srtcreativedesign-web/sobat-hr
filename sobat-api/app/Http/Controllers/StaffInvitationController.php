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
}
