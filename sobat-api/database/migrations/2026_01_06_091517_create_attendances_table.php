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
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->date('date');
            $table->time('clock_in')->nullable();
            $table->time('clock_out')->nullable();
            $table->string('clock_in_source')->nullable(); // fingerprint, manual, mobile
            $table->string('clock_out_source')->nullable();
            $table->enum('status', ['present', 'late', 'absent', 'leave', 'overtime'])->default('present');
            $table->integer('work_duration')->nullable(); // in minutes
            $table->text('notes')->nullable();
            $table->timestamps();
            
            $table->index(['employee_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
