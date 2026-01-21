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
        Schema::create('payrolls_ref', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->onDelete('cascade');
            $table->string('period', 7); // YYYY-MM
            $table->string('account_number')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            $table->integer('days_present')->default(0);
            
            // Salary
            $table->decimal('basic_salary', 15, 2)->default(0);
            
            // Allowances
            $table->decimal('meal_rate', 15, 2)->default(0);
            $table->decimal('meal_amount', 15, 2)->default(0);
            $table->decimal('transport_rate', 15, 2)->default(0);
            $table->decimal('transport_amount', 15, 2)->default(0);
            $table->decimal('attendance_rate', 15, 2)->default(0);
            $table->decimal('attendance_amount', 15, 2)->default(0);
            $table->decimal('health_allowance', 15, 2)->default(0);
            $table->decimal('position_allowance', 15, 2)->default(0);
            
            $table->decimal('total_salary_1', 15, 2)->default(0); // Subtotal 1
            
            // Overtime
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->integer('overtime_hours')->default(0);
            $table->decimal('overtime_amount', 15, 2)->default(0);
            
            // Bonus & Incentives
            $table->decimal('bonus', 15, 2)->default(0);
            $table->decimal('incentive', 15, 2)->default(0);
            $table->decimal('holiday_allowance', 15, 2)->default(0); // THR/Insentif Lebaran
            
            $table->decimal('total_salary_2', 15, 2)->default(0); // Gross
            
            $table->decimal('policy_ho', 15, 2)->default(0); // Kebijakan HO
            
            // Deductions
            $table->decimal('deduction_absent', 15, 2)->default(0); // Potongan Absen
            $table->decimal('deduction_alpha', 15, 2)->default(0); // Potongan Alfa
            $table->decimal('deduction_shortage', 15, 2)->default(0); // Selisih SO
            $table->decimal('deduction_loan', 15, 2)->default(0); // Pinjaman
            $table->decimal('deduction_admin_fee', 15, 2)->default(0); // Adm Bank
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0); // BPJS TK
            
            $table->decimal('deduction_total', 15, 2)->default(0);
            
            // Finals
            $table->decimal('grand_total', 15, 2)->default(0);
            $table->decimal('ewa_amount', 15, 2)->default(0); // EWA
            $table->decimal('net_salary', 15, 2)->default(0); // Final Net
            
            // Status & Approval
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payrolls_ref');
    }
};
