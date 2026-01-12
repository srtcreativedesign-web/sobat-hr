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
        Schema::create('invitations', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('name')->nullable();
            $table->json('payload')->nullable(); // data awal dari excel
            $table->string('token')->unique();
            $table->enum('status', ['pending', 'queued', 'sent', 'failed', 'accepted'])->default('pending');
            $table->text('error_message')->nullable();
            $table->datetime('expires_at')->nullable();
            $table->datetime('password_generated_at')->nullable();
            $table->text('password_encrypted')->nullable(); // untuk menyimpan password sementara terenkripsi
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('invitations');
    }
};
