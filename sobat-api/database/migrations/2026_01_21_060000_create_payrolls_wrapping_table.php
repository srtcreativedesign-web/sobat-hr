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
        Schema::create('payrolls_wrapping', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->onDelete('cascade');
            $table->string('period'); // YYYY-MM
            $table->string('status')->default('draft'); // draft, approved, paid
            
            // Employee Info Snapshot
            $table->string('employee_name');
            $table->string('employee_code')->nullable();
            $table->string('position')->nullable();
            $table->string('department')->nullable();
            $table->string('account_number')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            $table->integer('days_present')->default(0);
            
            // Income
            $table->decimal('basic_salary', 15, 2)->default(0);
            $table->decimal('training_salary', 15, 2)->default(0); // Col M
            
            $table->decimal('meal_rate', 15, 2)->default(0);
            $table->decimal('meal_amount', 15, 2)->default(0);
            
            $table->decimal('transport_rate', 15, 2)->default(0);
            $table->decimal('transport_amount', 15, 2)->default(0);
            
            $table->decimal('attendance_allowance', 15, 2)->default(0); // Tunjangan Kehadiran
            $table->decimal('health_allowance', 15, 2)->default(0);
            $table->decimal('bonus', 15, 2)->default(0);
            
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->decimal('overtime_hours', 15, 2)->default(0);
            $table->decimal('overtime_amount', 15, 2)->default(0);
            
            $table->decimal('target_koli', 15, 2)->default(0); // Col AA
            $table->decimal('fee_aksesoris', 15, 2)->default(0); // Col AB
            
            $table->decimal('total_salary_gross', 15, 2)->default(0); // AC: Total Gaji & Bonus
            
            $table->decimal('adj_bpjs', 15, 2)->default(0); // AD: Adj gaji terpotong BPJS
            
            // Deductions
            $table->decimal('deduction_absent', 15, 2)->default(0); // Absen 1X
            $table->decimal('deduction_late', 15, 2)->default(0);
            $table->decimal('deduction_alpha', 15, 2)->default(0); // Tidak Hadir
            $table->decimal('deduction_loan', 15, 2)->default(0); // Pinjaman
            $table->decimal('deduction_admin_fee', 15, 2)->default(0);
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0);
            
            $table->decimal('deduction_total', 15, 2)->default(0);
            
            // Totals
            $table->decimal('net_salary', 15, 2)->default(0);
            $table->decimal('ewa_amount', 15, 2)->default(0); // Pinjaman EWA (Col AM?)
            
            // Approval
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users');
            
            $table->timestamps();
            
            // Unique constraint
            $table->unique(['employee_id', 'period']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payrolls_wrapping');
    }
};
