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
        // 1. Leave Details (Cuti)
        Schema::create('leave_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('amount')->comment('Number of days');
            $table->text('reason');
            $table->timestamps();
        });

        // 2. Sick Leave Details (Sakit)
        Schema::create('sick_leave_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->date('start_date');
            $table->date('end_date');
            $table->text('reason')->nullable();
            $table->json('attachment')->nullable()->comment('Doctor note');
            $table->timestamps();
        });

        // 3. Overtime Details (Lembur)
        Schema::create('overtime_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->integer('duration')->comment('Duration in minutes'); 
            $table->text('reason'); // Description
            $table->timestamps();
        });

        // 4. Business Trip Details (Perjalanan Dinas)
        Schema::create('business_trip_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->string('destination'); // Title or Destination
            $table->date('start_date');
            $table->date('end_date');
            $table->text('purpose');
            $table->decimal('budget', 15, 2)->nullable(); // Estimated Cost
            $table->timestamps();
        });

        // 5. Reimbursement Details (Reimburse Medis/Kacamata)
        Schema::create('reimbursement_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->date('date')->nullable(); // Date of receipt/expense
            $table->string('title'); // Type or Title
            $table->text('description'); // Keterangan
            $table->decimal('amount', 15, 2);
            $table->json('attachment')->nullable();
            $table->timestamps();
        });

        // 6. Asset Details (Pengajuan Aset)
        Schema::create('asset_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('requests')->onDelete('cascade');
            $table->string('brand')->nullable(); // Merek
            $table->text('specification')->nullable();
            $table->decimal('amount', 15, 2)->nullable(); // Estimasi Harga
            $table->boolean('is_urgent')->default(false);
            $table->text('reason')->nullable(); // Kebutuhan (reason)
            $table->json('attachment')->nullable(); // Foto Barang
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('asset_details');
        Schema::dropIfExists('reimbursement_details');
        Schema::dropIfExists('business_trip_details');
        Schema::dropIfExists('overtime_details');
        Schema::dropIfExists('sick_leave_details');
        Schema::dropIfExists('leave_details');
    }
};
