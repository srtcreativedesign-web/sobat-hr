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
            $table->string('device_id')->nullable()->after('fcm_token')->comment('Unique device identifier for mobile app binding');
            $table->string('device_name')->nullable()->after('device_id')->comment('Device model name for display purposes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['device_id', 'device_name']);
        });
    }
};
