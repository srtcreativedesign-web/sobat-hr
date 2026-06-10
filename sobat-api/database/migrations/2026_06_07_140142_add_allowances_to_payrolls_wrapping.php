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
            $table->decimal('position_allowance', 15, 2)->nullable()->after('health_allowance');
            $table->decimal('holiday_allowance', 15, 2)->nullable()->after('bonus');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payrolls_wrapping', function (Blueprint $table) {
            $table->dropColumn(['position_allowance', 'holiday_allowance']);
        });
    }
};
