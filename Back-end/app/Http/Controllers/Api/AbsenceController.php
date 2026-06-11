<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absence;
use App\Models\Cours;
use App\Services\AbsenceService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AbsenceController extends Controller
{
    /**
     * Saisir les présences/absences pour un cours.
     */
    public function saisirPresences(Request $request, int $ecole_id, int $cours_id): JsonResponse
    {
        $user  = $request->user();
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($cours_id);

        if (!$user->isAdmin() && !$user->isEnseignant()) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        if ($user->isEnseignant() && $cours->enseignant_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Vous ne pouvez saisir les présences que pour vos propres cours.'], 403);
        }

        $validated = $request->validate([
            'presences'               => 'required|array|min:1',
            'presences.*.etudiant_id' => 'required|exists:users,id',
            'presences.*.present'     => 'required|boolean',
            'presences.*.observation' => 'nullable|string|max:500',
        ]);

        $resultats           = [];
        $notificationService = new NotificationService();
        $absenceService      = new AbsenceService($ecole_id);

        $cours->load('ecue');

        foreach ($validated['presences'] as $presence) {
            $absence = Absence::updateOrCreate(
                ['cours_id' => $cours_id, 'etudiant_id' => $presence['etudiant_id']],
                [
                    'ecole_id'           => $ecole_id,
                    'present'            => $presence['present'],
                    'observation'        => $presence['observation'] ?? null,
                    'justifiee'          => false,
                    'type_justification' => null,
                ]
            );

            $resultats[] = $absence;

            if (!$presence['present'] && $cours->ecue !== null) {
                $stats = $absenceService->verifierStatutExclusion(
                    $presence['etudiant_id'],
                    $cours->ecue->id,
                    $cours->semestre_id
                );

                $seuilEcue        = $stats['seuil_ecue'];
                $absencesEcue     = $stats['absences_ecue'];
                $seuilSemestre    = $stats['seuil_semestre'];
                $absencesSemestre = $stats['absences_semestre'];
                $seuilHeures      = $stats['seuil_heures'];
                $heuresSemestre   = $stats['heures_semestre'];

                if ($absencesEcue == ceil($seuilEcue * 2 / 3)) {
                    $notificationService->notifierAbsences($presence['etudiant_id'], $ecole_id, $cours->ecue->nom, $absencesEcue, $seuilEcue);
                }
                if ($absencesEcue >= $seuilEcue) {
                    $notificationService->envoyer($presence['etudiant_id'], 'Exclusion session 1', "Vous avez atteint le seuil d'absences en {$cours->ecue->nom}.", 'absence', $ecole_id, ['ecue_id' => $cours->ecue->id]);
                }
                if ($absencesSemestre == ceil($seuilSemestre * 2 / 3)) {
                    $notificationService->envoyer($presence['etudiant_id'], 'Alerte absences semestre', "Vous avez {$absencesSemestre} absences ce semestre. Seuil : {$seuilSemestre}.", 'absence', $ecole_id, []);
                }
                if ($absencesSemestre >= $seuilSemestre) {
                    $notificationService->envoyer($presence['etudiant_id'], 'Exclusion session 1 — Semestre', "Vous avez atteint le seuil d'absences du semestre.", 'absence', $ecole_id, []);
                }
                if ($heuresSemestre >= ($seuilHeures * 2 / 3) && $heuresSemestre < $seuilHeures) {
                    $notificationService->envoyer($presence['etudiant_id'], "Alerte heures d'absence", "Vous avez {$heuresSemestre}h d'absence. Seuil : {$seuilHeures}h.", 'absence', $ecole_id, []);
                }
                if ($heuresSemestre >= $seuilHeures) {
                    $notificationService->envoyer($presence['etudiant_id'], 'Exclusion sessions 1 & 2', "Vous avez dépassé {$seuilHeures}h d'absence.", 'absence', $ecole_id, []);
                }
            }
        }

        return response()->json(['success' => true, 'message' => 'Présences enregistrées avec succès.', 'data' => $resultats]);
    }

    /**
     * Justifier une absence.
     *
     * RÈGLES :
     * - Admin    → peut justifier n'importe quelle absence de l'école
     * - Enseignant → peut justifier UNIQUEMENT les absences de SES propres cours
     *
     * La justification sera visible par les deux (admin et enseignant du cours)
     * car la donnée est en base avec justifie_par = id de celui qui a justifié.
     */
    public function justifier(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user    = $request->user();
        $absence = Absence::where('ecole_id', $ecole_id)
                          ->with('cours')
                          ->findOrFail($id);

        if (!$user->isAdmin() && !$user->isEnseignant()) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        // CORRECTION : un enseignant ne peut justifier que les absences
        // des cours qu'il enseigne lui-même
        if ($user->isEnseignant()) {
            $cours = $absence->cours;
            if (!$cours || $cours->enseignant_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous ne pouvez justifier que les absences de vos propres cours.',
                ], 403);
            }
        }

        if ($absence->present) {
            return response()->json(['success' => false, 'message' => "Cet étudiant était présent, pas d'absence à justifier."], 422);
        }

        $validated = $request->validate([
            'type_justification' => 'required|in:permission,justificatif',
            'observation'        => 'nullable|string|max:500',
        ]);

        // Vérifier délai 72h pour justificatif uniquement
        if ($validated['type_justification'] === 'justificatif') {
            if ($absence->delaiJustificatifDepasse()) {
                return response()->json(['success' => false, 'message' => 'Le délai de 72h pour soumettre un justificatif est dépassé.'], 422);
            }
        }

        $absence->update([
            'justifiee'          => true,
            'type_justification' => $validated['type_justification'],
            'date_justification' => now(),
            'justifie_par'       => $user->id,
            'observation'        => $validated['observation'] ?? $absence->observation,
        ]);

        // Charger les relations pour la réponse complète
        $absence->load(['etudiant', 'justifiePar', 'cours.ecue']);

        return response()->json([
            'success' => true,
            'message' => 'Absence justifiée avec succès.',
            'data'    => $absence,
        ]);
    }

    /**
     * Lister les absences.
     * - Étudiant : ses propres absences
     * - Enseignant : absences de ses cours uniquement
     * - Admin : toutes les absences de l'école
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $query = Absence::with(['cours.ecue.ue', 'justifiePar', 'etudiant'])
            ->where('ecole_id', $ecole_id)
            ->where('present', false);

        if ($user->isEtudiant()) {
            // Étudiant : uniquement ses propres absences
            $query->where('etudiant_id', $user->id);

        } elseif ($user->isEnseignant()) {
            // Enseignant : absences des cours qu'il enseigne
            $mesCoursIds = Cours::where('ecole_id', $ecole_id)
                ->where('enseignant_id', $user->id)
                ->pluck('id');
            $query->whereIn('cours_id', $mesCoursIds);

            // Filtre optionnel par étudiant
            if ($request->filled('etudiant_id')) {
                $query->where('etudiant_id', (int) $request->input('etudiant_id'));
            }

        } else {
            // Admin : toutes les absences, filtre optionnel par étudiant
            if ($request->filled('etudiant_id')) {
                $query->where('etudiant_id', (int) $request->input('etudiant_id'));
            }
        }

        // Filtre commun : justifiée ou non
        if ($request->filled('justifiee')) {
            $query->where('justifiee', $request->boolean('justifiee'));
        }

        $absences = $query->orderByDesc('created_at')->get();

        return response()->json([
            'success' => true,
            'data'    => $absences,
            'total'   => $absences->count(),
        ]);
    }

    /**
     * Vérifier le statut d'exclusion d'un étudiant pour une ECUE.
     */
    public function statutExclusion(Request $request, int $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'etudiant_id' => 'required|exists:users,id',
            'ecue_id'     => 'required|exists:ecues,id',
            'semestre_id' => 'required|exists:semestres,id',
        ]);

        $service = new AbsenceService($ecole_id);
        $statut  = $service->verifierStatutExclusion(
            (int) $validated['etudiant_id'],
            (int) $validated['ecue_id'],
            (int) $validated['semestre_id']
        );

        return response()->json(['success' => true, 'data' => $statut]);
    }

    /**
     * Lister les présences d'un cours spécifique.
     * Inclut les étudiants présents ET absents avec leurs infos de justification.
     */
    public function presencesCours(Request $request, int $ecole_id, int $cours_id): JsonResponse
    {
        $user  = $request->user();
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($cours_id);

        // Enseignant : uniquement ses propres cours
        if ($user->isEnseignant() && $cours->enseignant_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        $presences = Absence::with(['etudiant', 'justifiePar'])
            ->where('ecole_id', $ecole_id)
            ->where('cours_id', $cours_id)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $presences,
            'total'   => $presences->count(),
        ]);
    }
}