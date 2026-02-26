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
        // Drop existing thrs table
        Schema::dropIfExists('thrs');

        // Recreate with simplified structure matching Excel format:
        // Nama Karyawan | Tahun | THR
        Schema::create('thrs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->string('division')->nullable(); // ho or op
            $table->string('year', 4);
            $table->decimal('amount', 15, 2)->default(0); // THR amount
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->json('details')->nullable(); // Extra info like masa_kerja
            $table->timestamps();

            // Unique constraint to prevent duplicate THR for same employee in same year
            $table->unique(['employee_id', 'year']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('thrs');
    }
};
