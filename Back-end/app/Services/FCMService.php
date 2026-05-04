<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use GuzzleHttp\Client;

class FCMService
{
    private string $projectId;
    private string $credentialsPath;
    private Client $client;

    public function __construct()
    {
        $this->projectId       = config('services.firebase.project_id');
        $this->credentialsPath = storage_path('app/firebase-credentials.json');
        $this->client          = new Client();
    }

    /**
     * Obtenir le token d'accès OAuth2 depuis le fichier JSON.
     */
    private function getAccessToken(): string
    {
        $scopes      = ['https://www.googleapis.com/auth/firebase.messaging'];
        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
        $token       = $credentials->fetchAuthToken();
        return $token['access_token'];
    }

    /**
     * Envoyer une notification à un token FCM spécifique.
     */
    public function envoyerNotification(string $fcmToken, string $titre, string $corps, array $data = []): bool
    {
        try {
            $accessToken = $this->getAccessToken();

            $this->client->post(
                "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send",
                [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $accessToken,
                        'Content-Type'  => 'application/json',
                    ],
                    'json' => [
                        'message' => [
                            'token'        => $fcmToken,
                            'notification' => [
                                'title' => $titre,
                                'body'  => $corps,
                            ],
                            'data' => array_map('strval', $data),
                        ],
                    ],
                ]
            );

            return true;

        } catch (\Exception $e) {
            \Log::error('FCM Error: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Envoyer une notification à plusieurs tokens.
     */
    public function envoyerAPlusieurS(array $fcmTokens, string $titre, string $corps, array $data = []): void
    {
        foreach ($fcmTokens as $token) {
            if ($token) {
                $this->envoyerNotification($token, $titre, $corps, $data);
            }
        }
    }
}