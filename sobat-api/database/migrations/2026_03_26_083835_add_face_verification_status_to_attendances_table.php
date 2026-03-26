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
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('face_verification_status')->nullable()->default(null)->after('face_verified')
                ->comment('pending = queued, verified = match, mismatch = no match, failed = error');
            $table->index('face_verification_status');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex(['face_verification_status']);
            $table->dropColumn('face_verification_status');
        });
    }
};
