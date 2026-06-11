<?php

namespace App\Services;

use App\Models\Devoir;
use App\Models\Ecue;
use App\Models\EcoleConfig;
use App\Models\Note;
use App\Models\Ue;

class MoyenneCalculatorService
{
    private ?EcoleConfig $config;

    public function __construct(int $ecole_id)
    {
        $this->config = EcoleConfig::where('ecole_id', $ecole_id)->first();
    }

    private function cfg(string $champ, mixed $defaut): mixed
    {
        return $this->config?->{$champ} ?? $defaut;
    }

    /**
     * Calculer la moyenne d'un étudiant pour une ECUE.
     *
     * CORRECTION — statut "en_attente" :
     * Si l'étudiant n'a pas encore composé dans cette matière
     * (pas d'examen créé ou note non saisie), on retourne
     * statut = 'en_attente' et moyenne = null au lieu de 0.
     * Cela permet de calculer les moyennes uniquement sur les
     * matières effectivement évaluées.
     */
    public function calculerMoyenneEcue(int $etudiant_id, int $ecue_id, int $classe_id, int $session = 1): array
    {
        $noteMinimaleExamen = (float) $this->cfg('note_minimale_examen', 5);
        $moyenneValidation  = (float) $this->cfg('moyenne_validation_ue', 10);
        $poidsCC            = (float) $this->cfg('poids_cc', 40) / 100;
        $poidsExamen        = (float) $this->cfg('poids_examen', 60) / 100;

        // Pas d'examen créé → en attente
        $examen = Devoir::where('ecue_id', $ecue_id)
            ->where('classe_id', $classe_id)
            ->where('type', 'EXAMEN')
            ->where('session', $session)
            ->first();

        if (!$examen) {
            return $this->resultatEnAttente('Aucun examen créé pour cette ECUE');
        }

        // Note non encore saisie → en attente
        $noteExamen = Note::where('devoir_id', $examen->id)
            ->where('etudiant_id', $etudiant_id)
            ->first();

        if (!$noteExamen) {
            return $this->resultatEnAttente('Note non encore saisie');
        }

        // Absent à l'examen
        if ($noteExamen->absent) {
            return [
                'moyenne'       => null,   // null = pas de valeur chiffrable
                'note_examen'   => 0,
                'moyenne_cc'    => null,
                'absent_examen' => true,
                'statut'        => 'rattrapage',
                'raison'        => 'Absent à l\'examen',
            ];
        }

        $noteExamenValeur = (float) $noteExamen->valeur;

        // Session 2 → note examen = 100%
        if ($session === 2) {
            return [
                'moyenne'       => round($noteExamenValeur, 2),
                'note_examen'   => $noteExamenValeur,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => $noteExamenValeur >= $moyenneValidation ? 'valide' : 'non_valide',
                'raison'        => null,
            ];
        }

        // Note sous le seuil → rattrapage direct
        if ($noteExamenValeur < $noteMinimaleExamen) {
            return [
                'moyenne'       => round($noteExamenValeur, 2),
                'note_examen'   => $noteExamenValeur,
                'moyenne_cc'    => null,
                'absent_examen' => false,
                'statut'        => 'rattrapage',
                'raison'        => "Note examen ({$noteExamenValeur}) < minimum ({$noteMinimaleExamen})",
            ];
        }

        // Notes CC (CC, TP, TD)
        $devoirsCC = Devoir::where('ecue_id', $ecue_id)
            ->where('classe_id', $classe_id)
            ->whereIn('type', ['CC', 'TP', 'TD'])
            ->where('session', 1)
            ->pluck('id');

        $notesCC = Note::whereIn('devoir_id', $devoirsCC)
            ->where('etudiant_id', $etudiant_id)
            ->where('absent', false)
            ->get();

        $moyenneCC = $notesCC->count() > 0 ? (float) $notesCC->avg('valeur') : 0.0;

        $moyenne = round(($moyenneCC * $poidsCC) + ($noteExamenValeur * $poidsExamen), 2);

        return [
            'moyenne'       => $moyenne,
            'note_examen'   => $noteExamenValeur,
            'moyenne_cc'    => round($moyenneCC, 2),
            'absent_examen' => false,
            'statut'        => $moyenne >= $moyenneValidation ? 'valide' : 'non_valide',
            'raison'        => null,
        ];
    }

    /**
     * Retourne un résultat "en attente" (pas encore composé).
     * moyenne = null → exclu des calculs de moyenne générale.
     */
    private function resultatEnAttente(string $raison = ''): array
    {
        return [
            'moyenne'       => null,   // null = exclu du calcul
            'note_examen'   => null,
            'moyenne_cc'    => null,
            'absent_examen' => false,
            'statut'        => 'en_attente',
            'raison'        => $raison,
        ];
    }

    /**
     * Calculer la moyenne d'une UE.
     * CORRECTION : on ignore les ECUE "en_attente" dans le calcul de moyenne.
     * La moyenne est calculée uniquement sur les ECUE évaluées.
     */
    public function calculerMoyenneUe(int $etudiant_id, int $ue_id, int $classe_id, int $session = 1): array
    {
        $noteMinimaleExamen = (float) $this->cfg('note_minimale_examen', 5);
        $moyenneValidation  = (float) $this->cfg('moyenne_validation_ue', 10);

        $ecues = Ecue::where('ue_id', $ue_id)->get();

        $sommeNotesCredits  = 0.0;
        $sommeCreditsEvalues = 0;   // Crédits des ECUE déjà évaluées uniquement
        $sommeCreditsTotal  = 0;    // Tous les crédits de l'UE
        $moyennesEcues      = [];

        foreach ($ecues as $ecue) {
            $resultat = $this->calculerMoyenneEcue($etudiant_id, $ecue->id, $classe_id, $session);

            $moyennesEcues[] = [
                'ecue_id'   => $ecue->id,
                'ecue_nom'  => $ecue->nom,
                'ecue_code' => $ecue->code ?? '',
                'credits'   => $ecue->credits,
                ...$resultat,
            ];

            $sommeCreditsTotal += $ecue->credits;

            // CORRECTION : on n'inclut dans le calcul que les ECUE évaluées
            if ($resultat['statut'] !== 'en_attente' && $resultat['moyenne'] !== null) {
                $sommeNotesCredits   += $resultat['moyenne'] * $ecue->credits;
                $sommeCreditsEvalues += $ecue->credits;
            }
        }

        // Moyenne UE calculée sur les ECUE évaluées seulement
        $moyenneUe = $sommeCreditsEvalues > 0
            ? round($sommeNotesCredits / $sommeCreditsEvalues, 2)
            : null;  // null si aucune ECUE évaluée

        $aEcueEliminatoire = collect($moyennesEcues)
            ->contains(fn($e) => $e['note_examen'] !== null
                && $e['note_examen'] < $noteMinimaleExamen);

        // UE validée seulement si on a une moyenne et qu'elle est suffisante
        $ueValidee = $moyenneUe !== null
            && $moyenneUe >= $moyenneValidation
            && !$aEcueEliminatoire;

        // Toutes les ECUE en attente ?
        $touteEnAttente = collect($moyennesEcues)->every(fn($e) => $e['statut'] === 'en_attente');

        return [
            'ue_id'               => $ue_id,
            'moyenne_ue'          => $moyenneUe,
            'validee'             => $ueValidee,
            'a_ecue_eliminatoire' => $aEcueEliminatoire,
            'toute_en_attente'    => $touteEnAttente,
            'credits_total'       => $sommeCreditsTotal,
            'credits_evalues'     => $sommeCreditsEvalues,
            'ecues'               => $moyennesEcues,
        ];
    }

    /**
     * Calculer la moyenne d'un semestre.
     * CORRECTION : calcul uniquement sur les UE/ECUE déjà évaluées.
     * Les matières "en attente" ne faussent pas la moyenne.
     */
    public function calculerMoyenneSemestre(int $etudiant_id, int $semestre_id, int $classe_id, int $session = 1): array
    {
        $moyenneValidation  = (float) $this->cfg('moyenne_validation_ue', 10);
        $noteMinimaleExamen = (float) $this->cfg('note_minimale_examen', 5);

        $ues = Ue::where('semestre_id', $semestre_id)->get();

        $sommeNotesCredits   = 0.0;
        $sommeCreditsEvalues = 0;
        $moyennesUes         = [];
        $uesValidees         = 0;

        foreach ($ues as $ue) {
            $resultatUe    = $this->calculerMoyenneUe($etudiant_id, $ue->id, $classe_id, $session);
            $moyennesUes[] = $resultatUe;

            // N'inclure dans le calcul que les UE avec au moins une ECUE évaluée
            if (!$resultatUe['toute_en_attente'] && $resultatUe['moyenne_ue'] !== null) {
                $sommeNotesCredits   += $resultatUe['moyenne_ue'] * $resultatUe['credits_evalues'];
                $sommeCreditsEvalues += $resultatUe['credits_evalues'];
            }

            if ($resultatUe['validee']) {
                $uesValidees++;
            }
        }

        // Moyenne générale calculée sur les crédits évalués uniquement
        $moyenneSemestre = $sommeCreditsEvalues > 0
            ? round($sommeNotesCredits / $sommeCreditsEvalues, 2)
            : null;  // null si rien n'est encore évalué

        $totalUes    = $ues->count();
        $majoritéUes = $totalUes > 0 && $uesValidees >= ceil($totalUes / 2);

        $aucuneEcueSousCinq = !collect($moyennesUes)
            ->flatMap(fn($u) => $u['ecues'])
            ->contains(fn($e) => $e['note_examen'] !== null
                && $e['note_examen'] < $noteMinimaleExamen);

        $compense = $moyenneSemestre !== null
            && !$this->semestreValideNormalement($moyennesUes)
            && $moyenneSemestre >= $moyenneValidation
            && $aucuneEcueSousCinq
            && $majoritéUes;

        $statut = $moyenneSemestre === null
            ? 'en_attente'
            : $this->determinerStatutSemestre($moyennesUes, $compense);

        return [
            'semestre_id'    => $semestre_id,
            'moyenne'        => $moyenneSemestre,   // null si rien évalué
            'statut'         => $statut,
            'ues_validees'   => $uesValidees,
            'total_ues'      => $totalUes,
            'ues'            => $moyennesUes,
        ];
    }

    private function semestreValideNormalement(array $moyennesUes): bool
    {
        return collect($moyennesUes)->every(fn($u) => $u['validee']);
    }

    private function determinerStatutSemestre(array $moyennesUes, bool $compense): string
    {
        if ($this->semestreValideNormalement($moyennesUes) || $compense) {
            return 'valide';
        }
        return 'rattrapage';
    }

    /**
     * Calculer le bilan annuel d'un étudiant.
     */
    public function calculerBilanAnnuel(int $etudiant_id, int $classe_id, array $semestre_ids): array
    {
        $seuilEnjambement = (float) $this->cfg('seuil_enjambement_pourcent', 50);

        $resultatsSemestres  = [];
        $sommeNotesCredits   = 0.0;
        $sommeCreditsEvalues = 0;
        $creditsValides      = 0;
        $creditsTotal        = 0;

        foreach ($semestre_ids as $semestre_id) {
            $resultatS1 = $this->calculerMoyenneSemestre($etudiant_id, $semestre_id, $classe_id, 1);
            $resultatS2 = $this->calculerMoyenneSemestre($etudiant_id, $semestre_id, $classe_id, 2);

            $resultat = $resultatS1['statut'] === 'rattrapage' ? $resultatS2 : $resultatS1;
            $resultatsSemestres[] = $resultat;

            $creditsUesSemestre = Ue::where('semestre_id', $semestre_id)
                ->with('ecues')
                ->get()
                ->flatMap(fn($ue) => $ue->ecues)
                ->sum('credits');

            $creditsTotal += $creditsUesSemestre;

            if ($resultat['moyenne'] !== null) {
                $sommeNotesCredits   += $resultat['moyenne'] * $creditsUesSemestre;
                $sommeCreditsEvalues += $creditsUesSemestre;
            }

            foreach ($resultat['ues'] as $ue) {
                if ($ue['validee']) {
                    $creditsValides += Ecue::where('ue_id', $ue['ue_id'])->sum('credits');
                }
            }
        }

        $moyenneAnnuelle = $sommeCreditsEvalues > 0
            ? round($sommeNotesCredits / $sommeCreditsEvalues, 2)
            : null;

        $pourcentageCredits = $creditsTotal > 0
            ? round(($creditsValides / $creditsTotal) * 100, 2)
            : 0.0;

        if ($pourcentageCredits === 100.0) {
            $statut = 'passage';
        } elseif ($pourcentageCredits >= $seuilEnjambement) {
            $statut = 'enjambement';
        } else {
            $statut = 'redoublement';
        }

        return [
            'moyenne_annuelle'    => $moyenneAnnuelle,
            'credits_valides'     => $creditsValides,
            'credits_total'       => $creditsTotal,
            'pourcentage_credits' => $pourcentageCredits,
            'statut'              => $statut,
            'semestres'           => $resultatsSemestres,
        ];
    }
}