<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class TimestampTamperingDetectionService
{
    /**
     * Maximum allowed time discrepancy (in seconds) before flagging
     */
    private const MAX_ALLOWED_DISCREPANCY_SECONDS = 300; // 5 minutes

    /**
     * Detect time tampering by comparing device timestamp with server timestamp
     * 
     * @param string $deviceTimestamp Timestamp from device (when button was pressed)
     * @param string $serverTimestamp Timestamp when server received the request
     * @param int|null $deviceUptimeSeconds Device uptime since boot (if available)
     * @return array ['tampered' => bool, 'discrepancy_seconds' => int, 'message' => string, 'severity' => string]
     */
    public function detectTampering(
        string $deviceTimestamp,
        string $serverTimestamp,
        ?int $deviceUptimeSeconds = null
    ): array {
        try {
            $deviceTime = new \DateTime($deviceTimestamp);
            $serverTime = new \DateTime($serverTimestamp);
            
            // Calculate time difference in seconds
            $discrepancy = abs($deviceTime->getTimestamp() - $serverTime->getTimestamp());
            
            // Determine severity
            $severity = 'none';
            $tampered = false;
            $message = 'No tampering detected';
            
            if ($discrepancy > self::MAX_ALLOWED_DISCREPANCY_SECONDS) {
                $tampered = true;
                $severity = 'high';
                $message = 'Time tampering detected: Device time differs significantly from server time';
                
                Log::warning('Timestamp Tampering Detected', [
                    'device_timestamp' => $deviceTimestamp,
                    'server_timestamp' => $serverTimestamp,
                    'discrepancy_seconds' => $discrepancy,
                    'device_uptime_seconds' => $deviceUptimeSeconds,
                    'severity' => $severity,
                ]);
            } elseif ($discrepancy > 60) {
                // Minor discrepancy (clock drift, timezone issues)
                $severity = 'low';
                $message = 'Minor time discrepancy detected (possible clock drift)';
                
                Log::info('Minor Time Discrepancy', [
                    'discrepancy_seconds' => $discrepancy,
                ]);
            }
            
            return [
                'tampered' => $tampered,
                'discrepancy_seconds' => $discrepancy,
                'message' => $message,
                'severity' => $severity,
            ];
            
        } catch (\Exception $e) {
            Log::error('Timestamp Tampering Detection Failed', [
                'error' => $e->getMessage(),
                'device_timestamp' => $deviceTimestamp,
                'server_timestamp' => $serverTimestamp,
            ]);
            
            return [
                'tampered' => false,
                'discrepancy_seconds' => 0,
                'message' => 'Detection failed: ' . $e->getMessage(),
                'severity' => 'error',
            ];
        }
    }

    /**
     * Validate device uptime consistency
     * 
     * @param int $currentUptimeSeconds Current device uptime
     * @param string|null $lastKnownTimestamp Last known valid timestamp from this device
     * @param int|null $lastKnownUptimeSeconds Last known uptime from this device
     * @return array ['valid' => bool, 'message' => string]
     */
    public function validateUptimeConsistency(
        int $currentUptimeSeconds,
        ?string $lastKnownTimestamp,
        ?int $lastKnownUptimeSeconds
    ): array {
        // If no previous data, can't validate
        if ($lastKnownTimestamp === null || $lastKnownUptimeSeconds === null) {
            return [
                'valid' => true,
                'message' => 'No previous uptime data for comparison',
            ];
        }

        try {
            $lastKnownTime = new \DateTime($lastKnownTimestamp);
            $currentTime = new \DateTime();
            
            // Expected uptime increase (time elapsed since last submission)
            $timeElapsed = $currentTime->getTimestamp() - $lastKnownTime->getTimestamp();
            $expectedUptime = $lastKnownUptimeSeconds + $timeElapsed;
            
            // Allow 10% tolerance for uptime reporting inaccuracies
            $tolerance = max(60, $expectedUptime * 0.1); // At least 60 seconds tolerance
            $uptimeDiff = abs($currentUptimeSeconds - $expectedUptime);
            
            if ($uptimeDiff > $tolerance) {
                Log::warning('Uptime Inconsistency Detected', [
                    'current_uptime' => $currentUptimeSeconds,
                    'expected_uptime' => $expectedUptime,
                    'uptime_diff' => $uptimeDiff,
                    'tolerance' => $tolerance,
                ]);
                
                return [
                    'valid' => false,
                    'message' => 'Device uptime inconsistency detected. Possible time manipulation.',
                ];
            }
            
            return [
                'valid' => true,
                'message' => 'Uptime consistent',
            ];
            
        } catch (\Exception $e) {
            return [
                'valid' => true,
                'message' => 'Uptime validation failed: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Get the severity level for admin review
     * 
     * @param int $discrepancySeconds
     * @return string 'approved' | 'pending' | 'rejected'
     */
    public function getReviewStatus(int $discrepancySeconds): string
    {
        if ($discrepancySeconds > self::MAX_ALLOWED_DISCREPANCY_SECONDS) {
            return 'pending'; // Requires HR review
        }
        
        return 'approved'; // Auto-approve
    }
}
