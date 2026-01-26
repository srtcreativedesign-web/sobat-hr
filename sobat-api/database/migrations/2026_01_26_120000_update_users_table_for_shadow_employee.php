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
            $table->string('password')->nullable()->change();
            $table->enum('registration_status', ['temporary', 'registered'])->default('registered')->after('is_active');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Reverting password to not nullable might fail if there are null values,
            // but strictly speaking this is the reverse operation.
            $table->string('password')->nullable(false)->change();
            $table->dropColumn('registration_status');
        });
    }
};
