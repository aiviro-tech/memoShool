<?php

namespace App\Services;

use App\Models\Devoir;
use App\Models\Ecue;
use App\Models\EcoleConfig;
use App\Models\Note;
use App\Models\Ue;

class MoyenneCalculatorService
{
    private EcoleConfig $config;

    public function __construct(int $ecole_id)
    {
        $this->config = EcoleConfig::where('ecole_id', $ecole_id)->firstOrFail();
    }

    /**
     * Calculer la moyenne d'un étudiant pour une ECUE (session 1 ou 2).
     */
    public function calculerMoyenneEcue(int $etudiant_id, int $ecue_id, int $classe_id, int $session = 1): array
    {
        // Récupérer l'examen
        $examen = Devoir::where('ecue_id', $ecue_id)
            ->where('classe_id', $classe_id)
            ->where('type', 'EXAMEN')
            ->where('session', $session)
            ->first();

        // Pas d'examen créé → incomplet
        if (!$examen) {
            return [
                'moyenne'       => 0,
                'note_examen'   => null,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => 'incomplet',
            ];
        }

        // Note non saisie → incomplet
        $noteExamen = Note::where('devoir_id', $examen->id)
            ->where('etudiant_id', $etudiant_id)
            ->first();

        if (!$noteExamen) {
            return [
                'moyenne'       => 0,
                'note_examen'   => null,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => 'incomplet',
            ];
        }

        // Absent à l'examen → note = 0 → rattrapage
        if ($noteExamen->absent) {
            return [
                'moyenne'       => 0,
                'note_examen'   => 0,
                'moyenne_cc'    => null,
                'absent_examen' => true,
                'statut'        => 'rattrapage',
            ];
        }

        $noteExamenValeur = $noteExamen->valeur;

        // Session 2 (rattrapage) → note examen = 100% de la moyenne
        if ($session === 2) {
            return [
                'moyenne'       => round($noteExamenValeur, 2),
                'note_examen'   => $noteExamenValeur,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => $noteExamenValeur >= $this->config->moyenne_validation_ue
                                    ? 'valide' : 'non_valide',
            ];
        }

        // Note examen < note minimale → rattrapage direct
        if ($noteExamenValeur < $this->config->note_minimale_examen) {
            return [
                'moyenne'       => round($noteExamenValeur, 2),
                'note_examen'   => $noteExamenValeur,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => 'rattrapage',
            ];
        }

        // Récupérer les notes CC (CC, TP, TD) session 1
        $devoirsCC = Devoir::where('ecue_id', $ecue_id)
            ->where('classe_id', $classe_id)
            ->whereIn('type', ['CC', 'TP', 'TD'])
            ->where('session', 1)
            ->pluck('id');

        $notesCC = Note::whereIn('devoir_id', $devoirsCC)
            ->where('etudiant_id', $etudiant_id)
            ->where('absent', false)
            ->get();

        // Moyenne CC
        $moyenneCC = $notesCC->count() > 0
            ? $notesCC->avg('valeur')
            : 0;

        // Note finale = (CC × poids_cc%) + (Examen × poids_examen%)
        $poidsCC     = $this->config->poids_cc / 100;
        $poidsExamen = $this->config->poids_examen / 100;

        $moyenne = ($moyenneCC * $poidsCC) + ($noteExamenValeur * $poidsExamen);
        $moyenne = round($moyenne, 2);

        return [
            'moyenne'       => $moyenne,
            'note_examen'   => $noteExamenValeur,
            'moyenne_cc'    => round($moyenneCC, 2),
            'absent_examen' => false,
            'statut'        => $moyenne >= $this->config->moyenne_validation_ue
                                ? 'valide' : 'non_valide',
        ];
    }

    /**
     * Calculer la moyenne d'une UE pour un étudiant.
     */
    public function calculerMoyenneUe(int $etudiant_id, int $ue_id, int $classe_id, int $session = 1): array
    {
        $ecues = Ecue::where('ue_id', $ue_id)->get();

        $sommeNotesCredits = 0;
        $sommeCredits      = 0;
        $moyennesEcues     = [];

        foreach ($ecues as $ecue) {
            $resultat = $this->calculerMoyenneEcue($etudiant_id, $ecue->id, $classe_id, $session);

            $moyennesEcues[] = [
                'ecue_id'  => $ecue->id,
                'ecue_nom' => $ecue->nom,
                'credits'  => $ecue->credits,
                ...$resultat,
            ];

            $sommeNotesCredits += $resultat['moyenne'] * $ecue->credits;
            $sommeCredits      += $ecue->credits;
        }

        $moyenneUe = $sommeCredits > 0
            ? round($sommeNotesCredits / $sommeCredits, 2)
            : 0;

        // UE éliminatoire si au moins une ECUE a note examen < note minimale
        $aEcueEliminatoire = collect($moyennesEcues)
            ->contains(fn($e) => $e['note_examen'] !== null
                && $e['note_examen'] < $this->config->note_minimale_examen);

        // UE validée si moyenne ≥ 10 et pas d'ECUE éliminatoire
        $ueValidee = $moyenneUe >= $this->config->moyenne_validation_ue
                     && !$aEcueEliminatoire;

        return [
            'ue_id'               => $ue_id,
            'moyenne_ue'          => $moyenneUe,
            'validee'             => $ueValidee,
            'a_ecue_eliminatoire' => $aEcueEliminatoire,
            'ecues'               => $moyennesEcues,
        ];
    }

    /**
     * Calculer la moyenne d'un semestre pour un étudiant.
     */
    public function calculerMoyenneSemestre(int $etudiant_id, int $semestre_id, int $classe_id, int $session = 1): array
    {
        $ues = Ue::where('semestre_id', $semestre_id)->get();

        $sommeNotesCredits = 0;
        $sommeCredits      = 0;
        $moyennesUes       = [];
        $uesValidees       = 0;

        foreach ($ues as $ue) {
            $resultatUe = $this->calculerMoyenneUe($etudiant_id, $ue->id, $classe_id, $session);
            $moyennesUes[] = $resultatUe;

            $creditsUe = Ecue::where('ue_id', $ue->id)->sum('credits');

            $sommeNotesCredits += $resultatUe['moyenne_ue'] * $creditsUe;
            $sommeCredits      += $creditsUe;

            if ($resultatUe['validee']) {
                $uesValidees++;
            }
        }

        $moyenneSemestre = $sommeCredits > 0
            ? round($sommeNotesCredits / $sommeCredits, 2)
            : 0;

        $totalUes    = $ues->count();
        $majoritéUes = $uesValidees >= ceil($totalUes / 2);

        // Conditions de compensation
        $aucuneEcueSousCinq = !collect($moyennesUes)
            ->flatMap(fn($u) => $u['ecues'])
            ->contains(fn($e) => $e['note_examen'] !== null
                && $e['note_examen'] < $this->config->note_minimale_examen);

        $compense = !$this->semestreValideNormalement($moyennesUes)
            && $moyenneSemestre >= $this->config->moyenne_validation_ue
            && $aucuneEcueSousCinq
            && $majoritéUes;

        $statut = $this->determinerStatutSemestre($moyennesUes, $compense);

        return [
            'semestre_id'  => $semestre_id,
            'moyenne'      => $moyenneSemestre,
            'statut'       => $statut,
            'ues_validees' => $uesValidees,
            'total_ues'    => $totalUes,
            'ues'          => $moyennesUes,
        ];
    }

    /**
     * Vérifier si le semestre est validé normalement (toutes UE ≥ 10).
     */
    private function semestreValideNormalement(array $moyennesUes): bool
    {
        return collect($moyennesUes)->every(fn($u) => $u['validee']);
    }

    /**
     * Déterminer le statut final du semestre.
     */
    private function determinerStatutSemestre(array $moyennesUes, bool $compense): string
    {
        if ($this->semestreValideNormalement($moyennesUes) || $compense) {
            return 'valide';
        }

        return 'rattrapage';
    }

    /**
     * Calculer le bilan annuel d'un étudiant (après les 2 semestres).
     */
    public function calculerBilanAnnuel(int $etudiant_id, int $classe_id, array $semestre_ids): array
    {
        $resultatsSemestres = [];
        $sommeNotesCredits  = 0;
        $sommeCredits       = 0;
        $creditsValides     = 0;
        $creditsTotal       = 0;

        foreach ($semestre_ids as $semestre_id) {
            // On prend la meilleure session disponible
            $resultatS1 = $this->calculerMoyenneSemestre($etudiant_id, $semestre_id, $classe_id, 1);
            $resultatS2 = $this->calculerMoyenneSemestre($etudiant_id, $semestre_id, $classe_id, 2);

            // On utilise session 2 si session 1 = rattrapage
            $resultat = $resultatS1['statut'] === 'rattrapage' ? $resultatS2 : $resultatS1;

            $resultatsSemestres[] = $resultat;

            // Crédits du semestre
            $creditsUesSemestre = Ue::where('semestre_id', $semestre_id)
                ->with('ecues')
                ->get()
                ->flatMap(fn($ue) => $ue->ecues)
                ->sum('credits');

            $sommeNotesCredits += $resultat['moyenne'] * $creditsUesSemestre;
            $sommeCredits      += $creditsUesSemestre;
            $creditsTotal      += $creditsUesSemestre;

            // Crédits validés = crédits des UE validées
            foreach ($resultat['ues'] as $ue) {
                if ($ue['validee']) {
                    $creditsValides += Ecue::where('ue_id', $ue['ue_id'])->sum('credits');
                }
            }
        }

        $moyenneAnnuelle = $sommeCredits > 0
            ? round($sommeNotesCredits / $sommeCredits, 2)
            : 0;

        // Pourcentage de crédits validés
        $pourcentageCredits = $creditsTotal > 0
            ? round(($creditsValides / $creditsTotal) * 100, 2)
            : 0;

        $seuilEnjambement = $this->config->seuil_enjambement_pourcent;

        // Statut final
        if ($pourcentageCredits === 100) {
            $statut = 'passage';
        } elseif ($pourcentageCredits >= $seuilEnjambement) {
            $statut = 'enjambement';
        } else {
            $statut = 'redoublement';
        }

        return [
            'moyenne_annuelle'      => $moyenneAnnuelle,
            'credits_valides'       => $creditsValides,
            'credits_total'         => $creditsTotal,
            'pourcentage_credits'   => $pourcentageCredits,
            'statut'                => $statut,
            'semestres'             => $resultatsSemestres,
        ];
    }
}