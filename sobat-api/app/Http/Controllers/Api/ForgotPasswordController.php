<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\OtpCode;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class ForgotPasswordController extends Controller
{
    /**
     * 1. Request OTP via WhatsApp
     */
    public function requestOtp(Request $request)
    {
        $request->validate([
            'phone_number' => 'required|string'
        ]);

        $phone = $request->phone_number;
        
        // Standardize phone number for Indonesian prefix
        if (substr($phone, 0, 1) === '0') {
            $phone = '62' . substr($phone, 1);
        } elseif (substr($phone, 0, 3) === '+62') {
            $phone = '62' . substr($phone, 3);
        }

        // Evaluate both "08..." and "628..." formats since the DB might store either.
        $phoneToSearch62 = $phone; // "628..."
        $phoneToSearch0 = '0' . substr($phone, 2); // "08..."

        // Verify if employee exists
        $employeeExists = \App\Models\Employee::where('phone', $phoneToSearch62)
            ->orWhere('phone', $phoneToSearch0)
            ->exists();
        if (!$employeeExists) {
            return response()->json([
                'status' => 'error',
                'message' => 'Nomor WhatsApp tidak terdaftar di sistem HRIS'
            ], 404);
        }

        // Rate Limiting (1 per min) per phone
        $lastOtp = OtpCode::where('phone_number', $phone)
            ->where('created_at', '>=', Carbon::now()->subMinute())
            ->first();

        if ($lastOtp) {
            return response()->json([
                'status' => 'error',
                'message' => 'Tunggu 1 menit sebelum meminta OTP lagi'
            ], 429);
        }

        $otpCode = (string) rand(100000, 999999);

        OtpCode::create([
            'phone_number' => $phone,
            'otp_code' => $otpCode,
            'expires_at' => Carbon::now()->addMinutes(5)
        ]);

        $message = "*SOBAT HRIS SYSTEM*\n\nKode OTP untuk reset password Anda adalah: *{$otpCode}*.\n\nKode ini berlaku selama 5 menit. JANGAN berikan kode ini kepada siapapun termasuk pihak administrasi.";

        try {
            $response = Http::post('http://127.0.0.1:3333/send-otp', [
                'number' => $phone,
                'message' => $message
            ]);

            if ($response->successful()) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'OTP berhasil dikirim ke WhatsApp Anda'
                ]);
            }
            return response()->json([
                'status' => 'error',
                'message' => 'Server gagal mengirim WhatsApp'
            ], 500);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Microservice WhatsApp Offline'
            ], 500);
        }
    }

    /**
     * 2. Verify OTP
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'phone_number' => 'required|string',
            'otp_code' => 'required|string|size:6'
        ]);

        $phone = $request->phone_number;
        if (substr($phone, 0, 1) === '0') {
            $phone = '62' . substr($phone, 1);
        }

        $validOtp = OtpCode::where('phone_number', $phone)
            ->where('otp_code', $request->otp_code)
            ->where('is_used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$validOtp) {
            return response()->json([
                'status' => 'error',
                'message' => 'Kode OTP salah atau sudah kedaluwarsa'
            ], 400);
        }

        $validOtp->update(['is_used' => true]);

        // Create a temporary reset token leveraging Laravel Password Reset logic or custom JWT
        // We'll create a custom hashed token for simplicity
        $resetToken = hash('sha256', $phone . $validOtp->otp_code . env('APP_KEY') . time());
        
        // Cache the token to be valid for 15 minutes
        \Illuminate\Support\Facades\Cache::put('reset_token_' . $resetToken, $phone, now()->addMinutes(15));

        return response()->json([
            'status' => 'success',
            'message' => 'OTP Valid',
            'reset_token' => $resetToken
        ]);
    }

    /**
     * 3. Reset Password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'reset_token' => 'required|string',
            'password' => 'required|string|min:6|confirmed'
        ]);

        $phone = \Illuminate\Support\Facades\Cache::get('reset_token_' . $request->reset_token);

        if (!$phone) {
            return response()->json([
                'status' => 'error',
                'message' => 'Sesi reset password tidak valid atau kedaluwarsa'
            ], 400);
        }

        $phoneToSearch62 = $phone;                 // "628..."
        $phoneToSearch0 = '0' . substr($phone, 2); // "08..."

        $employee = \App\Models\Employee::where('phone', $phoneToSearch62)
            ->orWhere('phone', $phoneToSearch0)
            ->first();
        if (!$employee || !$employee->user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Akun tidak ditemukan'
            ], 404);
        }

        // Update User Password
        $user = $employee->user;
        $user->password = \Illuminate\Support\Facades\Hash::make($request->password);
        $user->save();

        // Clear token
        \Illuminate\Support\Facades\Cache::forget('reset_token_' . $request->reset_token);

        return response()->json([
            'status' => 'success',
            'message' => 'Password berhasil diperbarui'
        ]);
    }
}
