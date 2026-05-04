<?php

namespace App\Services;

use App\Models\Absence;
use App\Models\Cours;
use App\Models\EcoleConfig;
use App\Models\Ecue;

class AbsenceService
{
    private EcoleConfig $config;

    public function __construct(int $ecole_id)
    {
        $this->config = EcoleConfig::where('ecole_id', $ecole_id)->firstOrFail();
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
            if (!$cours || !$cours->heure_debut || !$cours->heure_fin) return 0;

            $debut = \Carbon\Carbon::parse($cours->heure_debut);
            $fin   = \Carbon\Carbon::parse($cours->heure_fin);
            return $fin->diffInMinutes($debut) / 60; // en heures
        });
    }

    /**
     * Vérifier le statut d'exclusion d'un étudiant pour une ECUE.
     */
    public function verifierStatutExclusion(int $etudiant_id, int $ecue_id, int $semestre_id): array
    {
        $absencesEcue      = $this->compterAbsencesParEcue($etudiant_id, $ecue_id, $semestre_id);
        $absencesSemestre  = $this->compterAbsencesParSemestre($etudiant_id, $semestre_id);
        $heuresSemestre    = $this->compterHeuresAbsenceParSemestre($etudiant_id, $semestre_id);

        $excluS1Ecue       = $absencesEcue     > $this->config->absences_max_par_ecue;
        $excluS1Semestre   = $absencesSemestre  > $this->config->absences_max_par_semestre;
        $excluS1S2         = $heuresSemestre    > $this->config->heures_absence_exclusion_s1_s2;

        // Déterminer le statut final
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
            'statut'              => $statut,
            'absences_ecue'       => $absencesEcue,
            'absences_semestre'   => $absencesSemestre,
            'heures_semestre'     => round($heuresSemestre, 2),
            'seuil_ecue'          => $this->config->absences_max_par_ecue,
            'seuil_semestre'      => $this->config->absences_max_par_semestre,
            'seuil_heures'        => $this->config->heures_absence_exclusion_s1_s2,
        ];
    }
}