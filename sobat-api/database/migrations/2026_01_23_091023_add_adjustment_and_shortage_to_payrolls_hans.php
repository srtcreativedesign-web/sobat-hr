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
        Schema::table('payrolls_hans', function (Blueprint $table) {
            $table->decimal('adjustment', 15, 2)->default(0)->after('holiday_allowance')->comment('Adj Kekurangan Gaji');
            $table->decimal('deduction_so_shortage', 15, 2)->default(0)->after('deduction_late')->comment('Selisih SO');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payrolls_hans', function (Blueprint $table) {
            $table->dropColumn(['adjustment', 'deduction_so_shortage']);
        });
    }
};
