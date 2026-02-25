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
        Schema::create('thrs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->onDelete('cascade');
            $table->string('year', 4);
            $table->decimal('amount', 15, 2);
            $table->decimal('tax', 15, 2)->default(0);
            $table->decimal('net_amount', 15, 2);
            $table->enum('status', ['draft', 'approved', 'paid'])->default('draft');
            $table->json('details')->nullable(); // For breakdown like basic salary, allowances during calculation
            $table->text('approval_signature')->nullable();
            $table->string('signer_name')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users');
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            // Unique constraint to prevent duplicate THR for same employee in same year
            $table->unique(['employee_id', 'year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('thrs');
    }
};
