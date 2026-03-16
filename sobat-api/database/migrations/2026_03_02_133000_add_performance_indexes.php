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
        Schema::table('attendances', function (Blueprint $table) {
            if (!collect(Schema::getIndexes('attendances'))->pluck('name')->contains('attendances_employee_id_date_index')) {
                $table->index(['employee_id', 'date']);
            }
            if (!collect(Schema::getIndexes('attendances'))->pluck('name')->contains('attendances_status_index')) {
                $table->index('status');
            }
        });

        // 2. Indexing for Payrolls
        Schema::table('payrolls', function (Blueprint $table) {
            if (!collect(Schema::getIndexes('payrolls'))->pluck('name')->contains('payrolls_employee_id_period_index')) {
                $table->index(['employee_id', 'period']);
            }
            if (!collect(Schema::getIndexes('payrolls'))->pluck('name')->contains('payrolls_status_index')) {
                $table->index('status');
            }
        });

        // 3. Indexing for Requests
        Schema::table('requests', function (Blueprint $table) {
            if (!collect(Schema::getIndexes('requests'))->pluck('name')->contains('requests_employee_id_status_index')) {
                $table->index(['employee_id', 'status']);
            }
            if (!collect(Schema::getIndexes('requests'))->pluck('name')->contains('requests_type_index')) {
                $table->index('type');
            }
        });

        // 4. Indexing for Employees
        Schema::table('employees', function (Blueprint $table) {
            if (!collect(Schema::getIndexes('employees'))->pluck('name')->contains('employees_full_name_index')) {
                $table->index('full_name');
            }
            if (!collect(Schema::getIndexes('employees'))->pluck('name')->contains('employees_status_index')) {
                $table->index('status');
            }
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
