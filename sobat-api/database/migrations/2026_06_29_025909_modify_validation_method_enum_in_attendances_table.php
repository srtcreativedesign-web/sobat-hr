<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("ALTER TABLE attendances MODIFY COLUMN validation_method ENUM('qr_code', 'gps', 'online_gps', 'dynamic_qr') DEFAULT 'online_gps'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE attendances MODIFY COLUMN validation_method ENUM('qr_code', 'gps', 'online_gps') DEFAULT 'online_gps'");
    }
};
