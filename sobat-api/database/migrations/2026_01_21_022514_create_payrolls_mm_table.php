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
        Schema::create('payrolls_mm', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->string('period', 7)->index(); // YYYY-MM
            
            $table->string('account_number')->nullable();
            
            // Attendance
            $table->integer('days_total')->default(0);
            $table->integer('days_off')->default(0);
            $table->integer('days_sick')->default(0);
            $table->integer('days_permission')->default(0);
            $table->integer('days_alpha')->default(0);
            $table->integer('days_leave')->default(0);
            $table->integer('days_present')->default(0);
            
            // Salary Components
            $table->decimal('basic_salary', 15, 2)->default(0);
            
            // Allowances
            $table->decimal('meal_rate', 10, 2)->default(0);
            $table->decimal('meal_amount', 12, 2)->default(0);
            
            $table->decimal('transport_rate', 10, 2)->default(0);
            $table->decimal('transport_amount', 12, 2)->default(0);
            
            $table->decimal('attendance_rate', 10, 2)->default(0);
            $table->decimal('attendance_amount', 12, 2)->default(0);
            
            $table->decimal('health_allowance', 12, 2)->default(0);
            $table->decimal('position_allowance', 12, 2)->default(0);
            
            $table->decimal('total_salary_1', 15, 2)->default(0); // Subtotal?
            
            // Overtime & Bonus
            $table->decimal('overtime_rate', 10, 2)->default(0);
            $table->decimal('overtime_hours', 8, 2)->default(0);
            $table->decimal('overtime_amount', 12, 2)->default(0);
            
            $table->decimal('bonus', 12, 2)->default(0); // Explicit Bonus column for MM
            $table->decimal('incentive', 12, 2)->default(0);
            $table->decimal('holiday_allowance', 12, 2)->default(0); // Insentif Lebaran
            
            $table->decimal('total_salary_2', 15, 2)->default(0); // Subtotal with bonus?
            
            $table->string('policy_ho')->nullable(); // Kebijakan HO
            
            // Deductions
            $table->decimal('deduction_absent', 12, 2)->default(0); // Potongan Absen
            $table->decimal('deduction_alpha', 12, 2)->default(0);
            $table->decimal('deduction_shortage', 12, 2)->default(0); // Selisih SO
            $table->decimal('deduction_loan', 12, 2)->default(0);
            $table->decimal('deduction_admin_fee', 12, 2)->default(0);
            $table->decimal('deduction_bpjs_tk', 12, 2)->default(0);
            
            $table->decimal('deduction_total', 15, 2)->default(0); // Jumlah Potongan
            
            // Finals
            $table->decimal('grand_total', 15, 2)->default(0);
            $table->decimal('ewa_amount', 12, 2)->default(0); // Pinjaman EWA
            $table->decimal('net_salary', 15, 2)->default(0); // Payroll
            
            // Status
            $table->string('status')->default('draft'); // draft, approved, paid
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payrolls_mm');
    }
};
