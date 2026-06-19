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
        // Alter requests status enum
        DB::statement("ALTER TABLE requests MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled', 'draft', 'spl_open', 'pending_final') DEFAULT 'draft'");

        Schema::table('overtime_details', function (Blueprint $table) {
            $table->json('proof_image_done')->nullable()->after('reason');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('overtime_details', function (Blueprint $table) {
            $table->dropColumn('proof_image_done');
        });

        // Reverting ENUM is tricky if data exists, but we'll reset it to original
        DB::statement("ALTER TABLE requests MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled', 'draft') DEFAULT 'draft'");
    }
};
