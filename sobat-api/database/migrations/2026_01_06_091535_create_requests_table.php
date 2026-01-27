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
        Schema::create('requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('employee_id');
            // Updated Types
            $table->enum('type', ['leave', 'sick_leave', 'overtime', 'reimbursement', 'business_trip', 'resignation', 'asset']);
            $table->string('title');
            $table->text('description');
            $table->text('reason')->nullable();
            
            // Summary Fields for List View
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->decimal('amount', 15, 2)->nullable();
            $table->json('attachments')->nullable();

            $table->enum('status', ['pending', 'approved', 'rejected', 'cancelled', 'draft'])->default('draft');
            $table->integer('step_now')->default(1);
            $table->text('rejection_reason')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamps();
            
            $table->index(['employee_id', 'type', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('requests');
    }
};
