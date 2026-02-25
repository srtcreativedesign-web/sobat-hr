<?php

namespace App\Services;

use App\Models\User;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

class FcmService
{
    protected $client;
    protected $projectId;
    protected $serviceAccountPath;

    public function __construct()
    {
        $this->client = new Client();
        $this->projectId = env('FIREBASE_PROJECT_ID');
        $this->serviceAccountPath = storage_path('app/firebase/service-account.json');
    }

    /**
     * Send notification to a specific token
     */
    public function sendNotification($token, $title, $body, $data = [])
    {
        if (!$token) return false;

        try {
            $accessToken = $this->getAccessToken();
            if (!$accessToken) {
                Log::error('FCM: Failed to get access token');
                return false;
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => (object)$data,
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'sound' => 'default',
                        ],
                    ],
                ]
            ];

            $response = $this->client->post($url, [
                'headers' => [
                    'Authorization' => 'Bearer ' . $accessToken,
                    'Content-Type' => 'application/json',
                ],
                'json' => $payload,
            ]);

            $isSuccess = $response->getStatusCode() === 200;
            Log::info("FCM Send to $token: " . ($isSuccess ? 'Success' : 'Failed (' . $response->getStatusCode() . ')'));

            return $isSuccess;
        } catch (\Exception $e) {
            Log::error('FCM Error: ' . $e->getMessage());
            if (method_exists($e, 'getResponse') && $e->getResponse()) {
                Log::error('FCM Error Body: ' . $e->getResponse()->getBody()->getContents());
            }
            return false;
        }
    }

    /**
     * Send notification to all users who have an FCM token
     */
    public function broadcastNotification($title, $body, $data = [])
    {
        $users = User::whereNotNull('fcm_token')->get();
        $successCount = 0;

        foreach ($users as $user) {
            if ($this->sendNotification($user->fcm_token, $title, $body, $data)) {
                $successCount++;
            }
        }

        return $successCount;
    }

    /**
     * Generate Google Access Token using Service Account
     * Requires: google/auth package
     */
    protected function getAccessToken()
    {
        if (!file_exists($this->serviceAccountPath)) {
            Log::warning('FCM: Service account file not found at ' . $this->serviceAccountPath);
            return null;
        }

        try {
            // If the package google/auth is not installed, we can suggest it.
            // For now, assume it's or provide a simple implementation if possible.
            // Recommendation: composer require google/auth
            
            // This is a simplified logic, usually we use Google\Client
            if (!class_exists('\Google\Client')) {
                 Log::error('FCM: Google Client library not found. Run: composer require google/apiclient');
                 return null;
            }

            $client = new \Google\Client();
            $client->setAuthConfig($this->serviceAccountPath);
            $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
            $client->fetchAccessTokenWithAssertion();
            $token = $client->getAccessToken();

            return $token['access_token'] ?? null;
        } catch (\Exception $e) {
            Log::error('FCM Token Error: ' . $e->getMessage());
            return null;
        }
    }
}
