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
        Schema::table('payrolls_wrapping', function (Blueprint $table) {
            $table->decimal('mandatory_overtime_rate', 15, 2)->nullable()->after('overtime_amount');
            $table->decimal('mandatory_overtime_amount', 15, 2)->nullable()->after('mandatory_overtime_rate');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payrolls_wrapping', function (Blueprint $table) {
            $table->dropColumn(['mandatory_overtime_rate', 'mandatory_overtime_amount']);
        });
    }
};
