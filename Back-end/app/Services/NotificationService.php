<?php

namespace App\Services;

use App\Models\FcmToken;
use App\Models\Notification;

class NotificationService
{
    private FCMService $fcmService;

    public function __construct()
    {
        $this->fcmService = new FCMService();
    }

    /**
     * Envoyer une notification à un utilisateur.
     */
    public function envoyer(
        int $userId,
        string $titre,
        string $contenu,
        string $type,
        ?int $ecoleId = null,
        array $data = []
    ): Notification {
        // Sauvegarder en base
        $notification = Notification::create([
            'user_id'  => $userId,
            'ecole_id' => $ecoleId,
            'titre'    => $titre,
            'contenu'  => $contenu,
            'type'     => $type,
            'data'     => $data,
            'lu'       => false,
        ]);

        // Envoyer push FCM
        $tokens = FcmToken::where('user_id', $userId)->pluck('token')->toArray();
        if (!empty($tokens)) {
            $this->fcmService->envoyerAPlusieurS($tokens, $titre, $contenu, array_merge(
                $data,
                ['type' => $type, 'notification_id' => $notification->id]
            ));
        }

        return $notification;
    }

    /**
     * Envoyer une notification à plusieurs utilisateurs.
     */
    public function envoyerAPlusieurS(
        array $userIds,
        string $titre,
        string $contenu,
        string $type,
        ?int $ecoleId = null,
        array $data = []
    ): void {
        foreach ($userIds as $userId) {
            $this->envoyer($userId, $titre, $contenu, $type, $ecoleId, $data);
        }
    }

    // ─── Méthodes spécifiques par type ───────────────────────────

    /**
     * Notification : nouveau support validé.
     */
    public function notifierSupportValide(int $coursId, int $ecoleId, array $etudiantIds): void
    {
        $this->envoyerAPlusieurS(
            $etudiantIds,
            'Nouveau support disponible',
            'Un nouveau support de cours vient d\'être validé.',
            'support',
            $ecoleId,
            ['cours_id' => $coursId]
        );
    }

    /**
     * Notification : nouveau cours programmé ou modifié.
     */
    public function notifierCoursProgramme(int $coursId, int $ecoleId, array $userIds, bool $modification = false): void
    {
        $titre   = $modification ? 'Emploi du temps modifié' : 'Nouveau cours programmé';
        $contenu = $modification
            ? 'Un cours de votre emploi du temps a été modifié.'
            : 'Un nouveau cours a été ajouté à votre emploi du temps.';

        $this->envoyerAPlusieurS(
            $userIds,
            $titre,
            $contenu,
            'emploi_du_temps',
            $ecoleId,
            ['cours_id' => $coursId]
        );
    }

    /**
     * Notification : note disponible.
     */
    public function notifierNoteDisponible(int $etudiantId, int $ecoleId, string $ecueNom, float $note): void
    {
        $this->envoyer(
            $etudiantId,
            'Note disponible',
            "Votre note en {$ecueNom} : {$note}/20",
            'note',
            $ecoleId,
            ['ecue_nom' => $ecueNom, 'note' => $note]
        );
    }

    /**
     * Notification : rappel échéance de paiement.
     */
    public function notifierEcheancePaiement(
        int $etudiantId, 
        int $ecoleId, 
        string $dateLimite, 
        float $soldeRestant,
        string $echeanceLibelle
    ): void {
        $this->envoyer(
            $etudiantId,
            'Rappel paiement',
            "{$echeanceLibelle} due le {$dateLimite}. Solde restant : " . number_format($soldeRestant, 0, ',', ' ') . " FCFA.",
            'paiement',
            $ecoleId,
            [
                'date_limite'      => $dateLimite,
                'solde_restant'    => $soldeRestant,
                'echeance_libelle' => $echeanceLibelle,
            ]
        );
    }

    /**
     * Notification : seuil d'absences approche.
     */
    public function notifierAbsences(int $etudiantId, int $ecoleId, string $ecueNom, int $nbAbsences, int $seuil): void
    {
        $this->envoyer(
            $etudiantId,
            'Alerte absences',
            "Vous avez {$nbAbsences} absence(s) en {$ecueNom}. Seuil maximum : {$seuil}.",
            'absence',
            $ecoleId,
            ['ecue_nom' => $ecueNom, 'nb_absences' => $nbAbsences, 'seuil' => $seuil]
        );
    }

    /**
     * Notification : nouvelle annonce.
     */
    public function notifierAnnonce(int $annonceId, int $ecoleId, array $userIds, string $titre): void
    {
        $this->envoyerAPlusieurS(
            $userIds,
            'Nouvelle annonce',
            $titre,
            'annonce',
            $ecoleId,
            ['annonce_id' => $annonceId]
        );
    }
}