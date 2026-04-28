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
        Schema::create('payroll_maximums', function (Blueprint $table) {
            $table->id();
            
            // Core
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('period'); // e.g. "2026-03"
            $table->string('account_number')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            $table->integer('days_present')->default(0);
            
            // Basic Salary
            $table->decimal('basic_salary', 15, 2)->default(0);
            
            // Allowances
            $table->decimal('attendance_rate', 15, 2)->default(0);
            $table->decimal('attendance_amount', 15, 2)->default(0);
            $table->decimal('transport_rate', 15, 2)->default(0);
            $table->decimal('transport_amount', 15, 2)->default(0);
            $table->decimal('health_allowance', 15, 2)->default(0);
            $table->decimal('position_allowance', 15, 2)->default(0);
            
            // Totals & Overtime
            $table->decimal('total_salary_1', 15, 2)->default(0);
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->decimal('overtime_hours', 10, 2)->default(0);
            $table->decimal('overtime_amount', 15, 2)->default(0);
            
            // Additional Incomes for Maximum 600
            $table->decimal('backup', 15, 2)->default(0);
            $table->decimal('insentif', 15, 2)->default(0); // Specific for max 600
            $table->decimal('insentif_kehadiran', 15, 2)->default(0);
            $table->decimal('holiday_allowance', 15, 2)->default(0);
            $table->decimal('adjustment', 15, 2)->default(0);
            $table->decimal('total_salary_2', 15, 2)->default(0); // This is Gross Salary
            
            // Policy & Deductions
            $table->decimal('policy_ho', 15, 2)->default(0);
            $table->decimal('deduction_absent', 15, 2)->default(0);
            $table->decimal('deduction_late', 15, 2)->default(0);
            $table->decimal('deduction_shortage', 15, 2)->default(0);
            $table->decimal('deduction_loan', 15, 2)->default(0);
            $table->decimal('deduction_admin_fee', 15, 2)->default(0);
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0);
            $table->decimal('total_deductions', 15, 2)->default(0);
            
            // Finals
            $table->decimal('grand_total', 15, 2)->default(0); // usually AJ
            $table->decimal('thp', 15, 2)->default(0); // (AK)
            $table->decimal('stafbook_loan', 15, 2)->default(0); // EWA / Pinjaman ke stafbook (AL)
            $table->decimal('net_salary', 15, 2)->default(0); // Total gaji ditransfer (AM)
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payroll_maximums');
    }
};
