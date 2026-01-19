<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('payroll_fnb', function (Blueprint $table) {
            $table->id();
            
            // Core Identification
            $table->unsignedBigInteger('employee_id');
            $table->string('period', 7); // YYYY-MM format
            $table->string('account_number', 50)->nullable();
            
            // Attendance Data (Jumlah columns D-J)
            $table->integer('days_total')->default(0); // Hari
            $table->integer('days_off')->default(0); // Off
            $table->integer('days_sick')->default(0); // Sakit
            $table->integer('days_permission')->default(0); // Ijin
            $table->integer('days_alpha')->default(0); // Alfa
            $table->integer('days_leave')->default(0); // Cuti
            $table->integer('days_present')->default(0); // Ada
            
            // Basic Salary (K)
            $table->decimal('basic_salary', 15, 2)->default(0);
            
            // Allowances with Rate and Amount
            $table->decimal('attendance_rate', 15, 2)->default(0); // Kehadiran/Hari (L)
            $table->decimal('attendance_amount', 15, 2)->default(0); // Kehadiran Jumlah (M)
            $table->decimal('transport_rate', 15, 2)->default(0); // Transport/Hari (N)
            $table->decimal('transport_amount', 15, 2)->default(0); // Transport Jumlah (O)
            $table->decimal('health_allowance', 15, 2)->default(0); // Tunj. Kesehatan (P)
            $table->decimal('position_allowance', 15, 2)->default(0); // Tunj. Jabatan (Q)
            
            // Total Salary 1 (R)
            $table->decimal('total_salary_1', 15, 2)->default(0); // Total Gaji
            
            // Overtime (S-U)
            $table->decimal('overtime_rate', 15, 2)->default(0); // Lembur/Jam (S)
            $table->decimal('overtime_hours', 8, 2)->default(0); // Lembur Jam (T)
            $table->decimal('overtime_amount', 15, 2)->default(0); // Lembur Jumlah (U)
            
            // Other Income (V-W)
            $table->decimal('holiday_allowance', 15, 2)->default(0); // Insentif Lebaran (V)
            $table->decimal('adjustment', 15, 2)->default(0); // Adj Kekurangan Gaji (W)
            
            // Total Salary 2 (X)
            $table->decimal('total_salary_2', 15, 2)->default(0); // Total Gaji (Rp)
            
            // Policy (Y)
            $table->decimal('policy_ho', 15, 2)->default(0); // Kebijakan HO
            
            // Deductions (Z-AE)
            $table->decimal('deduction_absent', 15, 2)->default(0); // Absen 1X (Z)
            $table->decimal('deduction_late', 15, 2)->default(0); // Terlambat (AA)
            $table->decimal('deduction_shortage', 15, 2)->default(0); // Selisih SO (AB)
            $table->decimal('deduction_loan', 15, 2)->default(0); // Pinjaman (AC)
            $table->decimal('deduction_admin_fee', 15, 2)->default(0); // Adm Bank (AD)
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0); // BPJS TK (AE)
            
            // Total Deductions (AF)
            $table->decimal('total_deductions', 15, 2)->default(0); // Jumlah Potongan
            
            // Final Calculations (AG-AI)
            $table->decimal('grand_total', 15, 2)->default(0); // Grand Total (AG)
            $table->decimal('ewa_amount', 15, 2)->default(0); // EWA (AH)
            $table->decimal('net_salary', 15, 2)->default(0); // Payroll (AI) - Final Take Home
            
            // Status and Metadata
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->json('details')->nullable(); // Additional data
            $table->text('notes')->nullable();
            
            $table->timestamps();
            
            // Indexes
            $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
            $table->index(['period', 'status']);
            $table->unique(['employee_id', 'period']); // One payroll per employee per period
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payroll_fnb');
    }
};
