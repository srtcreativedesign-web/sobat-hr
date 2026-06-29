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
        Schema::table('outlet_devices', function (Blueprint $table) {
            $table->string('device_code')->after('device_name')->unique()->nullable();
            $table->string('pin')->after('device_code')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('outlet_devices', function (Blueprint $table) {
            //
        });
    }
};
