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
        $tables = [
            'payrolls_wrapping',
            'payrolls_hans',
            'payrolls_ref',
            'payroll_cellullers',
            'payrolls_mm',
            'payrolls_money_changer'
        ];

        foreach ($tables as $tableName) {
            Schema::table($tableName, function (Blueprint $table) {
                if (!Schema::hasColumn($table->getTable(), 'backup')) {
                    $table->decimal('backup', 15, 2)->default(0)->after('accessory_fee');
                }
                if (!Schema::hasColumn($table->getTable(), 'insentif_kehadiran')) {
                    $table->decimal('insentif_kehadiran', 15, 2)->default(0)->after('backup');
                }
                if (!Schema::hasColumn($table->getTable(), 'attendance_rate')) {
                    $table->decimal('attendance_rate', 15, 2)->nullable()->after('basic_salary');
                }
                if (!Schema::hasColumn($table->getTable(), 'attendance_amount')) {
                    $table->decimal('attendance_amount', 15, 2)->nullable()->after('attendance_rate');
                }
                if (!Schema::hasColumn($table->getTable(), 'deduction_shortage')) {
                    $table->decimal('deduction_shortage', 15, 2)->nullable()->after('deduction_late');
                }
                if (!Schema::hasColumn($table->getTable(), 'deduction_so_shortage')) {
                    $table->decimal('deduction_so_shortage', 15, 2)->nullable()->after('deduction_shortage');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $tables = [
            'payrolls_wrapping',
            'payrolls_hans',
            'payrolls_ref',
            'payroll_cellullers',
            'payrolls_mm',
            'payrolls_money_changer'
        ];

        foreach ($tables as $tableName) {
            Schema::table($tableName, function (Blueprint $table) {
                // Not dropping to avoid data loss if rolled back
            });
        }
    }
};
