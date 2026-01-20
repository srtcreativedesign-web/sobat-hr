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
        Schema::table('payrolls', function (Blueprint $table) {
            $table->longText('approval_signature')->nullable()->after('status');
            $table->unsignedBigInteger('approved_by')->nullable()->after('approval_signature');
        });

        Schema::table('payroll_fnb', function (Blueprint $table) {
            $table->longText('approval_signature')->nullable()->after('status');
            $table->unsignedBigInteger('approved_by')->nullable()->after('approval_signature');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payrolls', function (Blueprint $table) {
            $table->dropColumn('approval_signature');
            $table->dropColumn('approved_by');
        });

        Schema::table('payroll_fnb', function (Blueprint $table) {
            $table->dropColumn('approval_signature');
            $table->dropColumn('approved_by');
        });
    }
};
