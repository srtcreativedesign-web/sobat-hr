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
        // 1. Indexing for Attendances
        Schema::table('attendances', function (Blueprint $blueprint) {
            $blueprint->index(['employee_id', 'date']);
            $blueprint->index('status');
        });

        // 2. Indexing for Payrolls
        Schema::table('payrolls', function (Blueprint $blueprint) {
            $blueprint->index(['employee_id', 'period']);
            $blueprint->index('status');
        });

        // 3. Indexing for Requests
        Schema::table('requests', function (Blueprint $blueprint) {
            $blueprint->index(['employee_id', 'status']);
            $blueprint->index('type');
        });

        // 4. Indexing for Employees
        Schema::table('employees', function (Blueprint $blueprint) {
            $blueprint->index('full_name');
            $blueprint->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $blueprint) {
            $blueprint->dropIndex(['employee_id', 'date']);
            $blueprint->dropIndex(['status']);
        });

        Schema::table('payrolls', function (Blueprint $blueprint) {
            $blueprint->dropIndex(['employee_id', 'period']);
            $blueprint->dropIndex(['status']);
        });

        Schema::table('requests', function (Blueprint $blueprint) {
            $blueprint->dropIndex(['employee_id', 'status']);
            $blueprint->dropIndex(['type']);
        });

        Schema::table('employees', function (Blueprint $blueprint) {
            $blueprint->dropIndex(['full_name']);
            $blueprint->dropIndex(['status']);
        });
    }
};
