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
        Schema::create('payroll_cellullers', function (Blueprint $table) {
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

            // Income
            $table->decimal('basic_salary', 15, 2)->default(0);
            $table->decimal('position_allowance', 15, 2)->default(0);
            
            $table->decimal('meal_rate', 15, 2)->default(0);
            $table->decimal('meal_amount', 15, 2)->default(0);
            
            $table->decimal('transport_rate', 15, 2)->default(0);
            $table->decimal('transport_amount', 15, 2)->default(0);
            
            $table->decimal('mandatory_overtime_rate', 15, 2)->default(0);
            $table->decimal('mandatory_overtime_amount', 15, 2)->default(0);
            
            $table->decimal('attendance_allowance', 15, 2)->default(0);
            $table->decimal('health_allowance', 15, 2)->default(0);
            
            $table->decimal('subtotal_1', 15, 2)->default(0); // Total Gaji Rutin
            
            // Overtime & Bonus
            $table->decimal('overtime_rate', 15, 2)->default(0);
            $table->decimal('overtime_hours', 8, 2)->default(0);
            $table->decimal('overtime_amount', 15, 2)->default(0);
            
            $table->decimal('bonus', 15, 2)->default(0); // Bonus
            $table->decimal('holiday_allowance', 15, 2)->default(0); // Insentif Lebaran / THR
            $table->decimal('adjustment', 15, 2)->default(0); // Adj Kekurangan Gaji
            
            $table->decimal('gross_salary', 15, 2)->default(0); // Total Gaji & Bonus (AB)
            $table->decimal('policy_ho', 15, 2)->default(0); // Kebijakan HO

            // Deductions
            $table->decimal('deduction_absent', 15, 2)->default(0); // Absen 1X
            $table->decimal('deduction_late', 15, 2)->default(0); // Terlambat
            $table->decimal('deduction_so_shortage', 15, 2)->default(0); // Selisih SO
            $table->decimal('deduction_loan', 15, 2)->default(0); // Pinjaman
            $table->decimal('deduction_admin_fee', 15, 2)->default(0); // Adm Bank
            $table->decimal('deduction_bpjs_tk', 15, 2)->default(0); // BPJS TK
            
            $table->decimal('total_deduction', 15, 2)->default(0); // Jumlah Potongan

            // Final
            $table->decimal('net_salary', 15, 2)->default(0); // Grand Total (AK)
            $table->decimal('ewa_amount', 15, 2)->default(0); // EWA
            $table->decimal('final_payment', 15, 2)->default(0); // PAYROLL (AM)

            // Extras
            $table->string('years_of_service')->nullable();
            $table->text('notes')->nullable();
            
            // Status & Approval
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->string('signer_name')->nullable();
            $table->text('approval_signature')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payroll_cellullers');
    }
};
