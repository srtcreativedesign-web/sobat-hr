<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Alter requests status enum to add spl_approved
        DB::statement("ALTER TABLE requests MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled', 'draft', 'spl_open', 'pending_final', 'spl_approved') DEFAULT 'draft'");

        Schema::table('overtime_details', function (Blueprint $table) {
            // Make end_time and duration nullable
            $table->time('end_time')->nullable()->change();
            $table->integer('duration')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('overtime_details', function (Blueprint $table) {
            $table->time('end_time')->nullable(false)->change();
            $table->integer('duration')->nullable(false)->change();
        });

        DB::statement("ALTER TABLE requests MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled', 'draft', 'spl_open', 'pending_final') DEFAULT 'draft'");
    }
};
