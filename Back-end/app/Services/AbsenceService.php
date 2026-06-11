<?php

namespace App\Services;

use App\Models\Absence;
use App\Models\EcoleConfig;

class AbsenceService
{
    private ?EcoleConfig $config;
    private bool $configDisponible;

    /**
     * CORRECTION : on utilise first() au lieu de firstOrFail().
     * firstOrFail() lançait une exception si la config n'existait pas,
     * ce qui faisait planter AbsenceController::saisirPresences()
     * et renvoyait "Configuration de l'école manquante" côté Flutter.
     *
     * Désormais on stocke si la config est disponible et on utilise
     * des valeurs par défaut si elle est absente, pour ne pas bloquer
     * l'enregistrement des présences.
     */
    public function __construct(int $ecole_id)
    {
        $this->config          = EcoleConfig::where('ecole_id', $ecole_id)->first();
        $this->configDisponible = $this->config !== null;
    }

    /**
     * Indique si la configuration est disponible.
     */
    public function configDisponible(): bool
    {
        return $this->configDisponible;
    }

    /**
     * Retourne la valeur d'un seuil avec une valeur par défaut
     * si la config n'existe pas.
     */
    private function seuil(string $champ, int $defaut): int
    {
        if (!$this->configDisponible) {
            return $defaut;
        }
        return (int) ($this->config->{$champ} ?? $defaut);
    }

    /**
     * Compter les absences non justifiées d'un étudiant pour une ECUE.
     */
    public function compterAbsencesParEcue(int $etudiant_id, int $ecue_id, int $semestre_id): int
    {
        return Absence::where('etudiant_id', $etudiant_id)
            ->where('present', false)
            ->where('justifiee', false)
            ->whereHas('cours', fn($q) => $q
                ->where('ecue_id', $ecue_id)
                ->where('semestre_id', $semestre_id)
            )->count();
    }

    /**
     * Compter les absences non justifiées d'un étudiant pour un semestre entier.
     */
    public function compterAbsencesParSemestre(int $etudiant_id, int $semestre_id): int
    {
        return Absence::where('etudiant_id', $etudiant_id)
            ->where('present', false)
            ->where('justifiee', false)
            ->whereHas('cours', fn($q) => $q->where('semestre_id', $semestre_id))
            ->count();
    }

    /**
     * Compter les heures d'absence non justifiées d'un étudiant pour un semestre.
     */
    public function compterHeuresAbsenceParSemestre(int $etudiant_id, int $semestre_id): float
    {
        $absences = Absence::where('etudiant_id', $etudiant_id)
            ->where('present', false)
            ->where('justifiee', false)
            ->whereHas('cours', fn($q) => $q->where('semestre_id', $semestre_id))
            ->with('cours')
            ->get();

        return $absences->sum(function ($absence) {
            $cours = $absence->cours;
            if (!$cours || !$cours->heure_debut || !$cours->heure_fin) {
                return 0;
            }
            $debut = \Carbon\Carbon::parse($cours->heure_debut);
            $fin   = \Carbon\Carbon::parse($cours->heure_fin);
            return $fin->diffInMinutes($debut) / 60;
        });
    }

    /**
     * Vérifier le statut d'exclusion d'un étudiant pour une ECUE.
     *
     * CORRECTION : utilise $this->seuil() avec valeurs par défaut
     * pour éviter le crash si config absente.
     */
    public function verifierStatutExclusion(int $etudiant_id, int $ecue_id, int $semestre_id): array
    {
        $absencesEcue     = $this->compterAbsencesParEcue($etudiant_id, $ecue_id, $semestre_id);
        $absencesSemestre = $this->compterAbsencesParSemestre($etudiant_id, $semestre_id);
        $heuresSemestre   = $this->compterHeuresAbsenceParSemestre($etudiant_id, $semestre_id);

        $seuilEcue      = $this->seuil('absences_max_par_ecue', 5);
        $seuilSemestre  = $this->seuil('absences_max_par_semestre', 10);
        $seuilHeures    = $this->seuil('heures_absence_exclusion_s1_s2', 30);

        $excluS1Ecue     = $absencesEcue     > $seuilEcue;
        $excluS1Semestre = $absencesSemestre  > $seuilSemestre;
        $excluS1S2       = $heuresSemestre    > $seuilHeures;

        if ($excluS1S2) {
            $statut = 'exclu_s1_s2';
        } elseif ($excluS1Semestre) {
            $statut = 'exclu_s1_semestre';
        } elseif ($excluS1Ecue) {
            $statut = 'exclu_s1_ecue';
        } else {
            $statut = 'autorise';
        }

        return [
            'statut'            => $statut,
            'absences_ecue'     => $absencesEcue,
            'absences_semestre' => $absencesSemestre,
            'heures_semestre'   => round($heuresSemestre, 2),
            'seuil_ecue'        => $seuilEcue,
            'seuil_semestre'    => $seuilSemestre,
            'seuil_heures'      => $seuilHeures,
        ];
    }
}