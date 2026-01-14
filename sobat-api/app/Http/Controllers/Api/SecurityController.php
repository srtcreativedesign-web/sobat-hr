<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class SecurityController extends Controller
{
    public function setupPin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|digits:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = auth()->user();
        $pin = $request->pin;

        // Check against Date of Birth (Security Rule)
        $employee = $user->employee; // Relation: user hasOne employee
        if ($employee && $employee->birth_date) {
            $dob = Carbon::parse($employee->birth_date);
            $formats = [
                $dob->format('dmy'), // 311299
                $dob->format('dmY'), // 31121999 (8 digits - unlikely but check)
                $dob->format('Ymd'), // 19991231
                $dob->format('ymd'), // 991231
            ];

            // Only check formats that result in 6 digits
            $forbidden = array_filter($formats, fn($f) => strlen($f) === 6);

            if (in_array($pin, $forbidden)) {
                return response()->json([
                    'message' => 'Demi keamanan, PIN tidak boleh menggunakan Tanggal Lahir Anda.',
                    'errors' => ['pin' => ['PIN tidak boleh sama dengan Tanggal Lahir.']]
                ], 422);
            }
        }

        $user->security_pin = Hash::make($pin);
        $user->save();

        return response()->json(['message' => 'PIN keamanan berhasil dibuat.']);
    }

    public function verifyPin(Request $request)
    {
        $request->validate([
            'pin' => 'required|digits:6',
        ]);

        $user = auth()->user();

        if (!$user->security_pin) {
            return response()->json(['message' => 'PIN belum diatur.'], 400);
        }

        if (Hash::check($request->pin, $user->security_pin)) {
            return response()->json(['message' => 'PIN valid.']);
        }

        return response()->json(['message' => 'PIN salah.'], 401);
    }
}
