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
        Schema::table('approvals', function (Blueprint $table) {
            // Drop the old wrong foreign key (pointing to users)
            $table->dropForeign(['approver_id']);
            
            // Add the correct foreign key (pointing to employees)
            $table->foreign('approver_id')
                  ->references('id')
                  ->on('employees')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('approvals', function (Blueprint $table) {
            $table->dropForeign(['approver_id']);
            
            $table->foreign('approver_id')
                  ->references('id')
                  ->on('users')
                  ->onDelete('cascade');
        });
    }
};
