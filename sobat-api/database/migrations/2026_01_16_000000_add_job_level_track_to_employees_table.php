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
            $table->string('job_level')->nullable()->after('position')->comment('crew, crew_leader, spv, manager_ops, staff, team_leader, deputy_manager, manager, director');
            $table->enum('track', ['operational', 'office'])->nullable()->after('job_level');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropColumn(['job_level', 'track']);
        });
    }
};
