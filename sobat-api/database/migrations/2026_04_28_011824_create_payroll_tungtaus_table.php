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
        Schema::create('payroll_tungtau', function (Blueprint $table) {
            $table->id();
            
            // Core
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->string('period', 7); // YYYY-MM
            $table->string('account_number')->nullable();
            
            // Status & Approval
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->text('notes')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_present')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            
            // Basic & Rates
            $table->decimal('basic_salary', 15, 2)->default(0);
            $table->decimal('attendance_rate', 15, 2)->default(0);
            $table->decimal('transport_rate', 15, 2)->default(0);
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->decimal('overtime_hours', 8, 2)->default(0);
            
            // Allowances / Incomes
            $table->decimal('attendance_amount', 15, 2)->default(0);
            $table->decimal('transport_amount', 15, 2)->default(0);
            $table->decimal('health_allowance', 15, 2)->default(0);
            $table->decimal('position_allowance', 15, 2)->default(0);
            $table->decimal('total_salary_1', 15, 2)->default(0); // Subtotal Gaji
            $table->decimal('overtime_amount', 15, 2)->default(0);
            $table->decimal('backup_allowance', 15, 2)->default(0); // Backup
            $table->decimal('attendance_incentive', 15, 2)->default(0); // Insentif Kehadiran
            $table->decimal('holiday_allowance', 15, 2)->default(0); // Insentif Lebaran
            $table->decimal('total_salary_2', 15, 2)->default(0); // Total Gaji & Bonus
            $table->decimal('policy_ho', 15, 2)->default(0); // Kebijakan HO
            $table->decimal('adjustment', 15, 2)->default(0); // Adjustment jika ada
            
            // Deductions
            $table->decimal('deduction_absent', 15, 2)->default(0); // Absen 1X
            $table->decimal('deduction_late', 15, 2)->default(0); // Terlambat
            $table->decimal('deduction_shortage', 15, 2)->default(0); // Selisih SO
            $table->decimal('deduction_loan', 15, 2)->default(0); // Pinjaman
            $table->decimal('deduction_admin_fee', 15, 2)->default(0); // Adm Bank
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0); // BPJS TK
            $table->decimal('total_deductions', 15, 2)->default(0); // Jumlah Potongan
            
            // Finals
            $table->decimal('grand_total', 15, 2)->default(0); // Grand Total
            $table->decimal('ewa_amount', 15, 2)->default(0); // EWA / Kasbon Stafbook
            $table->decimal('net_salary', 15, 2)->default(0); // THP
            
            $table->timestamps();
            
            $table->unique(['employee_id', 'period'], 'payroll_tt_emp_period_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payroll_tungtau');
    }
};
