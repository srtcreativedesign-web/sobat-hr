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
        Schema::table('users', function (Blueprint $table) {
            // Track type for attendance validation method
            $table->enum('track_type', ['head_office', 'operational'])->default('head_office')->after('email');
        });

        Schema::table('employees', function (Blueprint $table) {
            // Track type (denormalized from users table for easier queries)
            $table->enum('track_type', ['head_office', 'operational'])->default('head_office')->after('user_id');
            
            // Index for faster filtering
            $table->index('track_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('track_type');
        });

        Schema::table('employees', function (Blueprint $table) {
            $table->dropIndex(['track_type']);
            $table->dropColumn('track_type');
        });
    }
};
