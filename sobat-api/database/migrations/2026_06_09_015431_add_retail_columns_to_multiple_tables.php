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
                if (!Schema::hasColumn($table->getTable(), 'target_koli')) {
                    $table->decimal('target_koli', 15, 2)->default(0)->after('overtime_amount');
                }
                if (!Schema::hasColumn($table->getTable(), 'accessory_fee')) {
                    $table->decimal('accessory_fee', 15, 2)->default(0)->after('target_koli');
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
                $table->dropColumn(['target_koli', 'accessory_fee']);
            });
        }
    }
};
