<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasColumn('invitations', 'role')) {
            Schema::table('invitations', function (Blueprint $table) {
                $table->string('role')->default('staff')->after('name');
            });
        }

        if (!Schema::hasColumn('invitations', 'organization_id')) {
            Schema::table('invitations', function (Blueprint $table) {
                $table->foreignId('organization_id')->nullable()->after('role')->constrained('organizations')->nullOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            if (Schema::hasColumn('invitations', 'organization_id')) {
                $table->dropForeign(['organization_id']);
                $table->dropColumn('organization_id');
            }
            if (Schema::hasColumn('invitations', 'role')) {
                $table->dropColumn('role');
            }
        });
    }
};
