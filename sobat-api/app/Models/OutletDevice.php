<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OutletDevice extends Model
{
    protected $fillable = [
        'organization_id',
        'device_name',
        'device_code',
        'pin',
        'device_uid',
        'hardware_model',
        'activation_token',
        'secret_key',
        'status',
        'last_active_at'
    ];

    protected $casts = [
        'last_active_at' => 'datetime',
    ];

    protected static function booted()
    {
        static::creating(function ($model) {
            if (empty($model->secret_key)) {
                $model->secret_key = \Illuminate\Support\Str::random(64);
            }
            if (empty($model->device_code)) {
                $model->device_code = 'DEV-' . strtoupper(\Illuminate\Support\Str::random(6));
            }
        });
    }

    public function organization()
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Generate a new activation token for pairing.
     */
    public function generateActivationToken()
    {
        $this->activation_token = \Illuminate\Support\Str::random(32);
        $this->status = 'pending';
        $this->device_uid = null;
        $this->hardware_model = null;
        $this->save();
        
        return $this->activation_token;
    }

    /**
     * Bind a hardware device UID and activate the device.
     */
    public function activateWithDeviceUid($deviceUid)
    {
        $this->device_uid = $deviceUid;
        $this->status = 'active';
        $this->activation_token = null; // Token can only be used once
        $this->last_active_at = now();
        $this->save();
    }

    /**
     * Parse and validate the Dynamic QR Payload (Cryptography only).
     * Expected payload format: "device_uid|timestamp_iso8601|signature"
     * 
     * @return array ['valid' => true/false, 'message' => '...', 'qr_timestamp' => Carbon]
     */
    public function validateDynamicQr($qrPayload)
    {
        if ($this->status !== 'active') {
            return ['valid' => false, 'message' => 'Perangkat outlet ini tidak aktif.'];
        }

        $parts = explode('|', $qrPayload);
        if (count($parts) !== 3) {
            return ['valid' => false, 'message' => 'Format QR tidak valid.'];
        }

        list($scannedDeviceUid, $timestampStr, $signature) = $parts;

        if ($scannedDeviceUid !== $this->device_uid) {
            return ['valid' => false, 'message' => 'QR Code berasal dari perangkat yang berbeda.'];
        }

        try {
            $qrTimestamp = \Carbon\Carbon::parse($timestampStr);
        } catch (\Exception $e) {
            return ['valid' => false, 'message' => 'Waktu pada QR Code tidak valid.'];
        }

        $expectedSignature = hash_hmac('sha256', "{$scannedDeviceUid}|{$timestampStr}", $this->secret_key);
        
        if (!hash_equals($expectedSignature, $signature)) {
            return ['valid' => false, 'message' => 'Tanda tangan QR Code tidak valid (kemungkinan palsu).'];
        }

        return [
            'valid' => true, 
            'qr_timestamp' => $qrTimestamp,
            'message' => 'QR Code valid.'
        ];
    }
}
