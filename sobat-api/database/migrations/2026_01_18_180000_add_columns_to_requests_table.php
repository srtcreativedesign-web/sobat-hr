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
        Schema::table('requests', function (Blueprint $table) {
            // Check if column exists before adding it to avoid "Duplicate column" error
            if (!Schema::hasColumn('requests', 'title')) {
                $table->string('title')->nullable()->after('type');
            }
            if (!Schema::hasColumn('requests', 'description')) {
                $table->text('description')->nullable()->after('title');
            }
            if (!Schema::hasColumn('requests', 'start_date')) {
                $table->date('start_date')->nullable()->after('description');
            }
            if (!Schema::hasColumn('requests', 'end_date')) {
                $table->date('end_date')->nullable()->after('start_date');
            }
            if (!Schema::hasColumn('requests', 'amount')) {
                $table->decimal('amount', 8, 2)->nullable()->after('end_date');
            }
            if (!Schema::hasColumn('requests', 'attachments')) {
                $table->json('attachments')->nullable()->after('amount');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('requests', function (Blueprint $table) {
            $table->dropColumn(['title', 'description', 'start_date', 'end_date', 'amount', 'attachments']);
        });
    }
};
