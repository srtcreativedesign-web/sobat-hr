<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class GeofenceValidationService
{
    /**
     * Validate GPS coordinates against office geofence
     * 
     * @param float $latitude
     * @param float $longitude
     * @param float $officeLatitude Office coordinates
     * @param float $officeLongitude Office coordinates
     * @param int $radiusMeters Allowed radius in meters
     * @param int $toleranceMeters GPS tolerance buffer (default: 10m)
     * @return array ['valid' => bool, 'message' => string, 'data' => array|null]
     */
    public function validate(
        float $latitude,
        float $longitude,
        float $officeLatitude,
        float $officeLongitude,
        int $radiusMeters,
        int $toleranceMeters = 10
    ): array {
        // Calculate distance using Haversine formula
        $distance = $this->calculateDistance(
            $latitude,
            $longitude,
            $officeLatitude,
            $officeLongitude
        );

        $maxDistance = $radiusMeters + $toleranceMeters;

        if ($distance > $maxDistance) {
            Log::warning('GPS outside geofence', [
                'employee_lat' => $latitude,
                'employee_lng' => $longitude,
                'office_lat' => $officeLatitude,
                'office_lng' => $officeLongitude,
                'distance' => round($distance, 2),
                'allowed_radius' => $maxDistance,
            ]);

            return [
                'valid' => false,
                'message' => 'Anda berada di luar jangkauan kantor.',
                'data' => [
                    'distance_meters' => round($distance, 2),
                    'allowed_radius_meters' => $maxDistance,
                    'office_radius_meters' => $radiusMeters,
                    'tolerance_meters' => $toleranceMeters,
                ],
            ];
        }

        return [
            'valid' => true,
            'message' => 'Lokasi valid',
            'data' => [
                'distance_meters' => round($distance, 2),
                'allowed_radius_meters' => $maxDistance,
                'latitude' => $latitude,
                'longitude' => $longitude,
            ],
        ];
    }

    /**
     * Calculate distance between two GPS points in meters using Haversine formula
     * 
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @param float $earthRadius Earth radius in meters (default: 6371000)
     * @return float Distance in meters
     */
    public function calculateDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2,
        float $earthRadius = 6371000
    ): float {
        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(
            pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)
        ));

        return $angle * $earthRadius;
    }

    /**
     * Validate GPS coordinates against all hardcoded attendance locations
     *
     * @return array ['valid' => bool, 'message' => string, 'matched_location' => array|null, 'data' => array]
     */
    public function validateAgainstAllLocations(float $latitude, float $longitude): array
    {
        $locations = config('attendance_locations.locations');
        $tolerance = config('attendance_locations.tolerance_meters', 10);

        $minDistance = PHP_FLOAT_MAX;
        $nearest = null;

        foreach ($locations as $loc) {
            $distance = $this->calculateDistance(
                $latitude,
                $longitude,
                $loc['latitude'],
                $loc['longitude']
            );

            $maxAllowed = $loc['radius_meters'] + $tolerance;

            if ($distance <= $maxAllowed) {
                return [
                    'valid' => true,
                    'message' => 'Lokasi valid',
                    'matched_location' => $loc,
                    'data' => [
                        'location_id' => $loc['id'],
                        'location_name' => $loc['name'],
                        'distance_meters' => round($distance, 2),
                        'allowed_radius_meters' => $maxAllowed,
                    ],
                ];
            }

            if ($distance < $minDistance) {
                $minDistance = $distance;
                $nearest = $loc;
            }
        }

        Log::warning('GPS outside all attendance locations', [
            'employee_lat' => $latitude,
            'employee_lng' => $longitude,
            'nearest_location' => $nearest['name'] ?? null,
            'distance' => round($minDistance, 2),
        ]);

        return [
            'valid' => false,
            'message' => 'Anda berada di luar jangkauan lokasi yang diizinkan.',
            'matched_location' => null,
            'data' => [
                'nearest_location' => $nearest['name'] ?? null,
                'nearest_location_id' => $nearest['id'] ?? null,
                'distance_meters' => round($minDistance, 2),
            ],
        ];
    }

    /**
     * Get all configured attendance locations
     */
    public function getLocations(): array
    {
        return config('attendance_locations.locations', []);
    }

    /**
     * Get default Head Office coordinates
     *
     * @return array ['latitude' => float, 'longitude' => float, 'radius_meters' => int]
     */
    public function getDefaultHeadOffice(): array
    {
        // Default: Head Office coordinates
        // Can be overridden via .env config
        return [
            'latitude' => (float) config('app.office_latitude', -6.13778),
            'longitude' => (float) config('app.office_longitude', 106.62295),
            'radius_meters' => (int) config('app.office_radius', 100),
        ];
    }
}
