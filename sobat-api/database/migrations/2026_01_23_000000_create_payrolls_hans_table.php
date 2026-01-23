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
        Schema::create('payrolls_hans', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('employee_id');
            $table->string('period', 7); // YYYY-MM
            $table->string('account_number')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            $table->integer('days_long_shift')->default(0);
            $table->integer('days_present')->default(0);
            
            // Salary Components
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
            
            $table->decimal('total_salary_1', 15, 2)->default(0);
            
            // Overtime
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->integer('overtime_hours')->default(0);
            $table->decimal('overtime_amount', 15, 2)->default(0);
            
            // Bonuses
            $table->decimal('bonus', 15, 2)->default(0);
            $table->decimal('incentive', 15, 2)->default(0);
            $table->decimal('holiday_allowance', 15, 2)->default(0);
            
            $table->decimal('total_salary_2', 15, 2)->default(0);
            $table->decimal('policy_ho', 15, 2)->default(0);
            
            // Deductions
            $table->decimal('deduction_absent', 15, 2)->default(0);
            $table->decimal('deduction_late', 15, 2)->default(0);
            $table->decimal('deduction_alpha', 15, 2)->default(0);
            $table->decimal('deduction_loan', 15, 2)->default(0);
            $table->decimal('deduction_admin_fee', 15, 2)->default(0);
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0);
            
            $table->decimal('deduction_total', 15, 2)->default(0);
            
            // Finals
            $table->decimal('grand_total', 15, 2)->default(0);
            $table->decimal('ewa_amount', 15, 2)->default(0);
            $table->decimal('net_salary', 15, 2)->default(0);
            
            // Extras
            $table->string('years_of_service')->nullable();
            $table->text('notes')->nullable();
            
            // Status & Approval
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            
            $table->timestamps();
            
            // Foreign keys
            $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
            $table->foreign('approved_by')->references('id')->on('users');
            
            // Index for period and employee lookups
            $table->index(['period', 'employee_id']);
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payrolls_hans');
    }
};
