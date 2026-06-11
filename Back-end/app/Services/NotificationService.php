<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use App\Models\FcmToken;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Méthode centrale d'envoi de notification.
     * Tous les champs correspondent exactement au model et à la migration.
     */
    public function envoyer(
        int    $userId,
        string $titre,
        string $contenu,
        string $type,
        int    $ecoleId,
        array  $data = []
    ): void {
        if (trim($contenu) === '') return;

        Notification::create([
            'user_id'  => $userId,
            'ecole_id' => $ecoleId,
            'titre'    => $titre,
            'contenu'  => $contenu,
            'type'     => $type,
            'data'     => $data,
            'lu'       => false,
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // NOTES
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier un étudiant qu'une note est disponible.
     */
    public function notifierNoteDisponible(
        int    $etudiantId,
        int    $ecoleId,
        string $ecueNom,
        ?float $note,
        float  $bareme = 20
    ): void {
        if ($note === null) return;

        $this->envoyer(
            $etudiantId,
            'Nouvelle note disponible',
            "Votre note en {$ecueNom} est de {$note}/{$bareme}.",
            'note',
            $ecoleId,
            ['ecue_nom' => $ecueNom, 'note' => $note, 'bareme' => $bareme]
        );
    }

    // ─────────────────────────────────────────────────────────────────────
    // ABSENCES
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier un étudiant d'une alerte d'absences (préventive).
     */
    public function notifierAbsences(
        int    $etudiantId,
        int    $ecoleId,
        string $ecueNom,
        int    $absences,
        int    $seuil
    ): void {
        $reste = $seuil - $absences;
        $this->envoyer(
            $etudiantId,
            'Alerte absences',
            "Vous avez {$absences} absence(s) en {$ecueNom}. Plus que {$reste} avant exclusion.",
            'absence',
            $ecoleId,
            ['ecue_nom' => $ecueNom, 'absences' => $absences, 'seuil' => $seuil]
        );
    }

    // ─────────────────────────────────────────────────────────────────────
    // SUPPORTS DE COURS
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier les étudiants d'un cours qu'un support est disponible.
     */
    public function notifierSupportValide(
        int   $coursId,
        int   $ecoleId,
        array $etudiantIds
    ): void {
        foreach ($etudiantIds as $etudiantId) {
            $this->envoyer(
                $etudiantId,
                'Nouveau support disponible',
                "Un nouveau support de cours est disponible pour votre cours.",
                'support',
                $ecoleId,
                ['cours_id' => $coursId]
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // COURS
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier l'enseignant ET les étudiants de la classe qu'un cours a été créé.
     *
     * @param int    $enseignantId  ID de l'enseignant assigné
     * @param int    $ecoleId
     * @param string $ecueNom       Nom de l'ECUE
     * @param string $dateCours     Date du cours
     * @param string $heureDebut
     * @param string $heureFin
     * @param array  $etudiantIds   IDs des étudiants de la classe
     */
    public function notifierCoursCree(
        int    $enseignantId,
        int    $ecoleId,
        string $ecueNom,
        string $dateCours,
        string $heureDebut,
        string $heureFin,
        array  $etudiantIds = []
    ): void {
        $contenuEnseignant = "Un cours de {$ecueNom} vous a été assigné le {$dateCours} de {$heureDebut} à {$heureFin}.";
        $contenuEtudiant   = "Un cours de {$ecueNom} est planifié le {$dateCours} de {$heureDebut} à {$heureFin}.";
        $data = [
            'ecue_nom'   => $ecueNom,
            'date_cours' => $dateCours,
            'heure_debut'=> $heureDebut,
            'heure_fin'  => $heureFin,
        ];

        // Notification à l'enseignant
        $this->envoyer(
            $enseignantId,
            'Cours assigné',
            $contenuEnseignant,
            'emploi_du_temps',
            $ecoleId,
            $data
        );

        // Notification à chaque étudiant de la classe
        foreach ($etudiantIds as $etudiantId) {
            $this->envoyer(
                $etudiantId,
                'Nouveau cours planifié',
                $contenuEtudiant,
                'emploi_du_temps',
                $ecoleId,
                $data
            );
        }
    }

    /**
     * Notifier pour un cours programmé (création ou modification)
     * Cette méthode est appelée par CoursController
     */
    public function notifierCoursProgramme(
        int   $coursId,
        int   $ecoleId,
        array $userIds,
        bool  $estModification = false
    ): void {
        $cours = \App\Models\Cours::with(['ecue', 'classe'])->find($coursId);
        if (!$cours) return;

        $titre = $estModification ? 'Cours modifié' : 'Nouveau cours programmé';
        $message = $estModification
            ? "Le cours de {$cours->ecue->nom} du {$cours->date_cours} a été modifié."
            : "Un nouveau cours de {$cours->ecue->nom} est programmé le {$cours->date_cours} de {$cours->heure_debut} à {$cours->heure_fin}.";

        $data = [
            'cours_id'   => $coursId,
            'ecue_nom'   => $cours->ecue->nom,
            'date_cours' => $cours->date_cours->toDateString(),
            'heure_debut'=> $cours->heure_debut,
            'heure_fin'  => $cours->heure_fin,
        ];

        foreach ($userIds as $userId) {
            $this->envoyer(
                $userId,
                $titre,
                $message,
                'emploi_du_temps',
                $ecoleId,
                $data
            );
        }
    }

    /**
     * Notifier l'enseignant ET les étudiants d'un changement de statut de cours
     * (annulé, reporté, etc.).
     */
    public function notifierStatutCours(
        int    $enseignantId,
        int    $ecoleId,
        string $ecueNom,
        string $dateCours,
        string $statut,
        array  $etudiantIds = [],
        string $motif = ''
    ): void {
        $libelle = match($statut) {
            'annule'  => 'annulé',
            'reporte' => 'reporté',
            'termine' => 'terminé',
            default   => $statut,
        };

        $contenu = "Le cours de {$ecueNom} du {$dateCours} a été {$libelle}.";
        if ($motif) $contenu .= " Motif : {$motif}";

        $data = ['ecue_nom' => $ecueNom, 'date_cours' => $dateCours, 'statut' => $statut];

        $this->envoyer($enseignantId, "Cours {$libelle}", $contenu, 'emploi_du_temps', $ecoleId, $data);

        foreach ($etudiantIds as $etudiantId) {
            $this->envoyer($etudiantId, "Cours {$libelle}", $contenu, 'emploi_du_temps', $ecoleId, $data);
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // PAIEMENTS
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier l'étudiant que son paiement a été approuvé.
     */
    public function notifierPaiementApprouve(
        int    $etudiantId,
        int    $ecoleId,
        float  $montant,
        string $numeroPaiement = ''
    ): void {
        $contenu = "Votre paiement de {$montant} FCFA a été confirmé avec succès.";
        if ($numeroPaiement) $contenu .= " Référence : {$numeroPaiement}.";

        $this->envoyer(
            $etudiantId,
            'Paiement confirmé ✓',
            $contenu,
            'paiement',
            $ecoleId,
            ['montant' => $montant, 'numero' => $numeroPaiement]
        );
    }

    /**
     * Notifier l'étudiant que son paiement a échoué.
     */
    public function notifierPaiementEchoue(
        int   $etudiantId,
        int   $ecoleId,
        float $montant
    ): void {
        $this->envoyer(
            $etudiantId,
            'Paiement échoué',
            "Votre paiement de {$montant} FCFA n'a pas pu être traité. Veuillez réessayer.",
            'paiement',
            $ecoleId,
            ['montant' => $montant]
        );
    }

    // ─────────────────────────────────────────────────────────────────────
    // ANNONCES
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Notifier les destinataires d'une nouvelle annonce publiée.
     */
    public function notifierAnnonce(
        int    $annonceId,
        int    $ecoleId,
        array  $userIds,
        string $titreAnnonce
    ): void {
        foreach ($userIds as $userId) {
            $this->envoyer(
                $userId,
                'Nouvelle annonce',
                "Une nouvelle annonce a été publiée : {$titreAnnonce}.",
                'annonce',
                $ecoleId,
                ['annonce_id' => $annonceId, 'titre' => $titreAnnonce]
            );
        }
    }
}