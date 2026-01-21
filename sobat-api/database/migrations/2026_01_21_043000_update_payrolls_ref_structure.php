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
        Schema::table('payrolls_ref', function (Blueprint $table) {
            // New Attendance
            $table->integer('days_long_shift')->default(0)->after('days_leave');
            
            // New Deductions
            $table->decimal('deduction_late', 15, 2)->default(0)->after('deduction_absent');
            
            // Extras
            $table->string('years_of_service')->nullable()->after('net_salary');
            $table->text('notes')->nullable()->after('years_of_service');
            
            // Remove unused
            $table->dropColumn('deduction_shortage');
            // ewa_amount is not in Ref excel, but maybe good to keep for consistency? 
            // I'll keep ewa_amount but it might be unused.
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payrolls_ref', function (Blueprint $table) {
            $table->dropColumn(['days_long_shift', 'deduction_late', 'years_of_service', 'notes']);
            $table->decimal('deduction_shortage', 15, 2)->default(0);
        });
    }
};
