<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('location_id', 30)->nullable()->after('outlet_id');
            $table->string('location_name', 100)->nullable()->after('location_id');
            $table->index('location_id');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex(['location_id']);
            $table->dropColumn(['location_id', 'location_name']);
        });
    }
};
