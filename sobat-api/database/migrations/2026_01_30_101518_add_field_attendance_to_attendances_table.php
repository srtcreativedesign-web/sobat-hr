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
            // Add attendance type: office or field
            if (!Schema::hasColumn('attendances', 'attendance_type')) {
                $table->enum('attendance_type', ['office', 'field'])->default('office')->after('status');
            }
            
            // Add field notes (mandatory for field type)
            if (!Schema::hasColumn('attendances', 'field_notes')) {
                $table->text('field_notes')->nullable()->after('attendance_type');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn(['attendance_type', 'field_notes']);
            
            // Revert office coordinates to not nullable (if needed)
            // Note: This might fail if there are existing null values
            // $table->decimal('office_latitude', 10, 8)->nullable(false)->change();
            // $table->decimal('office_longitude', 11, 8)->nullable(false)->change();
        });
    }
};
