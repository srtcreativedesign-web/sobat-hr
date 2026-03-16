<?php

namespace App\Services;

use App\Models\QrCodeLocation;
use Illuminate\Support\Facades\Log;

class QrCodeValidationService
{
    /**
     * Validate QR code and return location data
     * 
     * @param string $qrCodeData The scanned QR code string
     * @return array ['valid' => bool, 'message' => string, 'data' => array|null]
     */
    public function validate(string $qrCodeData): array
    {
        // Check if QR code exists in database
        $qrLocation = QrCodeLocation::where('qr_code', $qrCodeData)
            ->where('is_active', true)
            ->with('organization')
            ->first();

        if (!$qrLocation) {
            Log::warning('Invalid QR Code scanned', [
                'qr_code' => $qrCodeData,
                'timestamp' => now()->toIso8601String()
            ]);

            return [
                'valid' => false,
                'message' => 'QR Code tidak valid atau sudah tidak aktif. Harap lapor ke HRD.',
                'data' => null,
            ];
        }

        // Return location data
        return [
            'valid' => true,
            'message' => 'QR Code valid',
            'data' => [
                'qr_location_id' => $qrLocation->id,
                'organization_id' => $qrLocation->organization_id,
                'organization_name' => $qrLocation->organization->name ?? null,
                'floor_number' => $qrLocation->floor_number,
                'location_name' => $qrLocation->location_name,
                'qr_code' => $qrLocation->qr_code,
            ],
        ];
    }

    /**
     * Generate unique QR code string for an outlet/floor
     * 
     * @param int $organizationId
     * @param int $floorNumber
     * @return string Format: OUTLET-{ORG_ID}-LT{FLOOR}-{TIMESTAMP}-{RANDOM}
     */
    public function generateQrCode(int $organizationId, int $floorNumber = 1): string
    {
        $timestamp = now()->timestamp;
        $random = strtoupper(substr(uniqid(), -4));
        
        return "OUTLET-{$organizationId}-LT{$floorNumber}-{$timestamp}-{$random}";
    }

    /**
     * Create QR code location entry
     * 
     * @param int $organizationId
     * @param int $floorNumber
     * @param string $locationName
     * @param string|null $notes
     * @return QrCodeLocation
     */
    public function createQrCodeLocation(
        int $organizationId,
        int $floorNumber = 1,
        string $locationName = '',
        ?string $notes = null
    ): QrCodeLocation {
        // Deactivate old codes for this organization and floor
        $this->deactivateOldCodes($organizationId, $floorNumber);

        $qrCode = $this->generateQrCode($organizationId, $floorNumber);

        return QrCodeLocation::create([
            'organization_id' => $organizationId,
            'qr_code' => $qrCode,
            'floor_number' => $floorNumber,
            'location_name' => $locationName ?: "Lantai {$floorNumber}",
            'notes' => $notes,
            'is_active' => true,
            'installed_at' => now(),
        ]);
    }

    /**
     * Deactivate all existing QR codes for an organization and floor
     */
    public function deactivateOldCodes(int $organizationId, int $floorNumber): void
    {
        QrCodeLocation::where('organization_id', $organizationId)
            ->where('floor_number', $floorNumber)
            ->where('is_active', true)
            ->update(['is_active' => false]);
    }

    /**
     * Batch generate QR codes for all outlets
     * 
     * @return array List of generated QR codes with outlet info
     */
    public function batchGenerateForOutlets(): array
    {
        $outlets = \App\Models\Organization::where('type', 'outlet')
            ->orWhere('type', 'branch')
            ->get();

        $generated = [];

        foreach ($outlets as $outlet) {
            // Default: 1 floor per outlet
            $qrLocation = $this->createQrCodeLocation(
                $outlet->id,
                1,
                "{$outlet->name} - Lantai 1",
                "Tempel QR Code di area yang terlihat CCTV"
            );

            $generated[] = [
                'outlet_id' => $outlet->id,
                'outlet_name' => $outlet->name,
                'floor' => 1,
                'qr_code' => $qrLocation->qr_code,
                'location_name' => $qrLocation->location_name,
            ];
        }

        return $generated;
    }
}
