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
        Schema::table('thrs', function (Blueprint $table) {
            $table->string('division')->nullable()->after('employee_id')->comment('ho or op');
            $table->index(['division', 'year']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('thrs', function (Blueprint $table) {
            $table->dropColumn('division');
        });
    }
};
