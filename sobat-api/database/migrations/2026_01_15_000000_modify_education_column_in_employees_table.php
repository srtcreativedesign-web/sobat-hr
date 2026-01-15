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
        // Change education column type to TEXT to allow storing JSON
        // Using raw statement to avoid doctrine/dbal dependency issues usually found in simple setups
        DB::statement('ALTER TABLE employees MODIFY education TEXT NULL');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert back to VARCHAR(255)
        DB::statement('ALTER TABLE employees MODIFY education VARCHAR(255) NULL');
    }
};
