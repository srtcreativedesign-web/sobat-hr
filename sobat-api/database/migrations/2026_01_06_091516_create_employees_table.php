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
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('employee_code')->unique();
            $table->string('full_name');
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->date('birth_date')->nullable();
            $table->enum('gender', ['male', 'female']);
            $table->unsignedBigInteger('organization_id');
            $table->string('position');
            $table->string('level')->nullable(); // Junior, Senior, Manager, dll
            $table->decimal('basic_salary', 15, 2)->default(0);
            $table->date('join_date');
            $table->date('contract_end_date')->nullable();
            $table->enum('employment_status', ['permanent', 'contract', 'probation'])->default('probation');
            $table->enum('status', ['active', 'inactive', 'resigned'])->default('active');
            $table->string('fingerprint_id')->nullable()->unique();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
