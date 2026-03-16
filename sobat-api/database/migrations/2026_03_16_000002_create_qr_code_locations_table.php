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
        Schema::create('qr_code_locations', function (Blueprint $table) {
            $table->id();
            
            // Reference to outlet/organization
            $table->foreignId('organization_id')->constrained()->onDelete('cascade');
            
            // Unique QR code string (will be encoded in QR)
            $table->string('qr_code')->unique();
            
            // Floor number (for multi-floor outlets)
            $table->integer('floor_number')->default(1);
            
            // Location name/label (e.g., "Lantai 1 - Area Kasir")
            $table->string('location_name');
            
            // Is this QR code active?
            $table->boolean('is_active')->default(true);
            
            // Installed at date
            $table->date('installed_at')->nullable();
            
            // Notes (e.g., "Tempel di dinding sebelah kanan")
            $table->text('notes')->nullable();
            
            // Timestamps
            $table->timestamps();
            
            // Indexes
            $table->index(['qr_code', 'is_active']);
            $table->index(['organization_id', 'floor_number']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('qr_code_locations');
    }
};
