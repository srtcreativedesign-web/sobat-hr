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
        Schema::table('employees', function (Blueprint $table) {
            $table->foreignId('division_id')->nullable()->after('organization_id')->constrained('divisions')->onDelete('set null');
            $table->foreignId('job_position_id')->nullable()->after('position')->constrained('job_positions')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropForeign(['division_id']);
            $table->dropColumn('division_id');
            $table->dropForeign(['job_position_id']);
            $table->dropColumn('job_position_id');
        });
    }
};
