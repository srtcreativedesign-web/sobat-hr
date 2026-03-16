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
        Schema::table('attendances', function (Blueprint $table) {
            $table->index('date');
        });

        Schema::table('employees', function (Blueprint $table) {
            $table->index(['status', 'employment_status', 'contract_end_date'], 'emp_dashboard_performance_idx');
        });

        Schema::table('payrolls', function (Blueprint $table) {
            $table->index('period');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex(['date']);
        });

        Schema::table('employees', function (Blueprint $table) {
            $table->dropIndex('emp_dashboard_performance_idx');
        });

        Schema::table('payrolls', function (Blueprint $table) {
            $table->dropIndex(['period']);
        });
    }
};
