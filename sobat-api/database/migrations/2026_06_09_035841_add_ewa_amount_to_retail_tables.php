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
                if (!Schema::hasColumn($table->getTable(), 'ewa_amount')) {
                    $table->decimal('ewa_amount', 15, 2)->nullable()->after('grand_total');
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
                // Keep the column if rolled back
            });
        }
    }
};
