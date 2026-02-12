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
        Schema::create('job_positions', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->nullable()->unique();
            $table->unsignedBigInteger('division_id')->nullable();
            $table->integer('level')->default(0); // 0=Staff, 1=SPV, 2=Manager, 3=GM/Director
            $table->unsignedBigInteger('parent_position_id')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('division_id')->references('id')->on('divisions')->onDelete('set null');
            $table->foreign('parent_position_id')->references('id')->on('job_positions')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('job_positions');
    }
};
