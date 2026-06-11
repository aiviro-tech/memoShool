<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use GuzzleHttp\Client;

class FCMService
{
    // ─── Nullable : config() peut retourner null si la clé est absente ───
    private ?string $projectId       = null;
    private ?string $credentialsPath = null;
    private ?Client $client          = null;

    /**
     * $throwOnMissingConfig = true  → comportement strict (ex: appel direct)
     * $throwOnMissingConfig = false → mode silencieux (NotificationService
     *   attrape l'exception et continue sans crash)
     */
    public function __construct(bool $throwOnMissingConfig = true)
    {
        $this->projectId       = config('services.firebase.project_id') ?: null;
        $this->credentialsPath = $this->resolveCredentialsPath();

        // Tenter de lire le project_id depuis le fichier JSON si absent de .env
        if (empty($this->projectId) && !empty($this->credentialsPath)) {
            $this->projectId = $this->loadProjectIdFromCredentials($this->credentialsPath);
        }

        $this->client = new Client();

        // Si la config est incomplète, on lève une exception UNIQUEMENT
        // si le mode strict est demandé. Le NotificationService appellera
        // avec throwOnMissingConfig=false et gérera lui-même le cas.
        if (empty($this->projectId) || empty($this->credentialsPath)) {
            if ($throwOnMissingConfig) {
                throw new \RuntimeException(
                    'Firebase FCM configuration invalide. ' .
                    'Vérifiez FIREBASE_PROJECT_ID et FIREBASE_CREDENTIALS dans .env, ' .
                    'ou placez firebase-credentials.json dans storage/app/.'
                );
            }
            // En mode silencieux : on marque l'instance comme non-opérationnelle
            // (projectId et credentialsPath restent null → isConfigured() = false)
        }
    }

    /**
     * Indique si le service est utilisable (config complète).
     */
    public function isConfigured(): bool
    {
        return !empty($this->projectId) && !empty($this->credentialsPath);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Résolution du chemin des identifiants Firebase
    // ─────────────────────────────────────────────────────────────────────
    private function resolveCredentialsPath(): ?string
    {
        $credentialConfig = config('services.firebase.credentials');

        if (!empty($credentialConfig)) {
            // Chemin direct vers un fichier existant
            if (is_string($credentialConfig) && file_exists($credentialConfig)) {
                return $credentialConfig;
            }

            // JSON inline → on l'écrit dans storage/app/firebase-credentials.json
            if (is_string($credentialConfig) && $this->isJsonString($credentialConfig)) {
                $path = storage_path('app/firebase-credentials.json');
                file_put_contents($path, $credentialConfig);
                return $path;
            }
        }

        // Fichier par défaut dans storage/app/
        $localPath = storage_path('app/firebase-credentials.json');
        if (file_exists($localPath)) {
            return $localPath;
        }

        return null;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Lecture du project_id depuis le fichier JSON de credentials
    // ─────────────────────────────────────────────────────────────────────
    private function loadProjectIdFromCredentials(string $path): ?string
    {
        if (!file_exists($path)) {
            return null;
        }

        $content = @file_get_contents($path);
        if ($content === false) {
            return null;
        }

        $json = json_decode($content, true);
        if (json_last_error() !== JSON_ERROR_NONE || !is_array($json)) {
            return null;
        }

        return !empty($json['project_id']) ? (string) $json['project_id'] : null;
    }

    private function isJsonString(string $value): bool
    {
        json_decode($value);
        return json_last_error() === JSON_ERROR_NONE;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Token OAuth2
    // ─────────────────────────────────────────────────────────────────────
    private function getAccessToken(): string
    {
        $scopes      = ['https://www.googleapis.com/auth/firebase.messaging'];
        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
        $token       = $credentials->fetchAuthToken();
        return $token['access_token'];
    }

    // ─────────────────────────────────────────────────────────────────────
    // Envoi d'une notification à un seul token FCM
    // ─────────────────────────────────────────────────────────────────────
    public function envoyerNotification(
        string $fcmToken,
        string $titre,
        string $corps,
        array  $data = []
    ): bool {
        // Sécurité : ne rien faire si mal configuré
        if (!$this->isConfigured()) {
            \Log::warning('FCMService: tentative d\'envoi sans configuration Firebase valide. Notification ignorée.');
            return false;
        }

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

    // ─────────────────────────────────────────────────────────────────────
    // Envoi à plusieurs tokens
    // ─────────────────────────────────────────────────────────────────────
    public function envoyerAPlusieurS(
        array  $fcmTokens,
        string $titre,
        string $corps,
        array  $data = []
    ): void {
        if (!$this->isConfigured()) {
            \Log::warning('FCMService: configuration manquante — notifications groupées ignorées.');
            return;
        }

        foreach ($fcmTokens as $token) {
            if (!empty($token)) {
                $this->envoyerNotification($token, $titre, $corps, $data);
            }
        }
    }
}