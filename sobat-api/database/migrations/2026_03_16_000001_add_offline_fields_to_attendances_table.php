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
        Schema::table('attendances', function (Blueprint $table) {
            // Track type: head_office or operational
            $table->enum('track_type', ['head_office', 'operational'])->default('head_office')->after('employee_id');
            
            // Validation method: how the location was validated
            $table->enum('validation_method', ['qr_code', 'gps', 'online_gps'])->default('online_gps')->after('track_type');
            
            // Offline submission flag
            $table->boolean('is_offline')->default(false)->after('validation_method');
            
            // QR Code data (for operational track)
            $table->string('qr_code_data')->nullable()->after('is_offline');
            
            // Outlet reference (for operational track)
            $table->foreignId('outlet_id')->nullable()->constrained('organizations')->after('qr_code_data');
            
            // Floor number (for operational track with multi-floor outlets)
            $table->integer('floor_number')->nullable()->after('outlet_id');
            
            // Device timestamp (when employee pressed the button)
            $table->timestamp('device_timestamp')->nullable()->after('floor_number');
            
            // Server timestamp (when server received the data)
            $table->timestamp('server_timestamp')->nullable()->after('device_timestamp');
            
            // Time discrepancy in seconds (for fraud detection)
            $table->integer('time_discrepancy_seconds')->nullable()->after('server_timestamp');
            
            // Device ID lock (prevent account sharing)
            $table->string('device_id')->nullable()->after('time_discrepancy_seconds');
            
            // Device uptime in seconds (for time tampering detection)
            $table->bigInteger('device_uptime_seconds')->nullable()->after('device_id');
            
            // Review status for offline submissions
            $table->enum('review_status', ['pending', 'approved', 'rejected'])->default('approved')->after('device_uptime_seconds');
            
            // Review notes (for HR admin)
            $table->text('review_notes')->nullable()->after('review_status');
            
            // Index for faster queries
            $table->index(['is_offline', 'review_status']);
            $table->index(['validation_method', 'track_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex(['is_offline', 'review_status']);
            $table->dropIndex(['validation_method', 'track_type']);
            $table->dropForeign(['outlet_id']);
            
            $table->dropColumn([
                'track_type',
                'validation_method',
                'is_offline',
                'qr_code_data',
                'outlet_id',
                'floor_number',
                'device_timestamp',
                'server_timestamp',
                'time_discrepancy_seconds',
                'device_id',
                'device_uptime_seconds',
                'review_status',
                'review_notes',
            ]);
        });
    }
};
