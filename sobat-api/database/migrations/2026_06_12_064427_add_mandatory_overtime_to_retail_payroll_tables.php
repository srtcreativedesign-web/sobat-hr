<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $tables = ['payrolls_money_changer', 'payrolls_hans', 'payrolls_minimarket', 'payrolls_reflexiology'];
        
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $t) use ($table) {
                    if (!Schema::hasColumn($table, 'mandatory_overtime_rate')) {
                        $t->decimal('mandatory_overtime_rate', 15, 2)->default(0)->after('overtime_amount');
                    }
                    if (!Schema::hasColumn($table, 'mandatory_overtime_amount')) {
                        $t->decimal('mandatory_overtime_amount', 15, 2)->default(0)->after('mandatory_overtime_rate');
                    }
                });
            }
        }
    }

    public function down(): void
    {
        $tables = ['payrolls_money_changer', 'payrolls_hans', 'payrolls_minimarket', 'payrolls_reflexiology'];
        
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $t) use ($table) {
                    if (Schema::hasColumn($table, 'mandatory_overtime_rate')) {
                        $t->dropColumn('mandatory_overtime_rate');
                    }
                    if (Schema::hasColumn($table, 'mandatory_overtime_amount')) {
                        $t->dropColumn('mandatory_overtime_amount');
                    }
                });
            }
        }
    }
};
