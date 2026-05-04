<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absence;
use App\Models\Cours;
use App\Services\AbsenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AbsenceController extends Controller
{
    /**
     * Saisir les présences/absences pour un cours.
     * Enseignant ou Admin uniquement.
     */
    public function saisirPresences(Request $request, int $ecole_id, int $cours_id): JsonResponse
    {
        $user  = $request->user();
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($cours_id);

        if (!$user->isAdmin() && !$user->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        // Un enseignant ne peut saisir que pour ses propres cours
        if ($user->isEnseignant() && $cours->enseignant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez saisir les présences que pour vos propres cours.',
            ], 403);
        }

        $validated = $request->validate([
            'presences'                => 'required|array|min:1',
            'presences.*.etudiant_id'  => 'required|exists:users,id',
            'presences.*.present'      => 'required|boolean',
            'presences.*.observation'  => 'nullable|string|max:500',
        ]);

        $resultats = [];

        foreach ($validated['presences'] as $presence) {
            $absence = Absence::updateOrCreate(
                [
                    'cours_id'    => $cours_id,
                    'etudiant_id' => $presence['etudiant_id'],
                ],
                [
                    'ecole_id'           => $ecole_id,
                    'present'            => $presence['present'],
                    'observation'        => $presence['observation'] ?? null,
                    'justifiee'          => false, // toujours false par défaut
                    'type_justification' => null,
                ]
            );

            $resultats[] = $absence;
        }

        $notificationService = new \App\Services\NotificationService();
        $absenceService      = new \App\Services\AbsenceService($ecole_id);

        $cours->load('ecue');

        foreach ($validated['presences'] as $presence) {
            if (!$presence['present']) {
                $stats    = $absenceService->verifierStatutExclusion(
                    $presence['etudiant_id'],
                    $cours->ecue->id,
                    $cours->semestre_id
                );

                $seuil    = $stats['seuil_ecue'];
                $absences = $stats['absences_ecue'];

                // Alerte préventive — 2/3 du seuil
                if ($absences == ceil($seuil * 2 / 3)) {
                    $notificationService->notifierAbsences(
                        $presence['etudiant_id'],
                        $ecole_id,
                        $cours->ecue->nom,
                        $absences,
                        $seuil
                    );
                }

                // Alerte critique — seuil atteint
                if ($absences >= $seuil) {
                    $notificationService->envoyer(
                        $presence['etudiant_id'],
                        'Exclusion session 1',
                        "Vous avez atteint le seuil d'absences en {$cours->ecue->nom}. Vous êtes exclu de la session 1.",
                        'absence',
                        $ecole_id,
                        ['ecue_id' => $cours->ecue->id, 'ecue_nom' => $cours->ecue->nom]
                    );
                }
            }
        }

        // Seuil 1 — nombre d'absences semestre
        $seuilSemestre    = $stats['seuil_semestre'];
        $absencesSemestre = $stats['absences_semestre'];

        // Alerte préventive
        if ($absencesSemestre == ceil($seuilSemestre * 2 / 3)) {
            $notificationService->envoyer(
                $presence['etudiant_id'],
                'Alerte absences semestre',
                "Vous avez {$absencesSemestre} absences ce semestre. Seuil maximum : {$seuilSemestre}.",
                'absence',
                $ecole_id,
                ['absences_semestre' => $absencesSemestre, 'seuil_semestre' => $seuilSemestre]
            );
        }

        // Seuil atteint → exclusion session 1
        if ($absencesSemestre >= $seuilSemestre) {
            $notificationService->envoyer(
                $presence['etudiant_id'],
                'Exclusion session 1 — Semestre',
                "Vous avez atteint le seuil d'absences du semestre. Vous êtes exclu de toutes les épreuves de la session 1.",
                'absence',
                $ecole_id,
                ['absences_semestre' => $absencesSemestre, 'seuil_semestre' => $seuilSemestre]
            );
        }

        // Seuil 2 — heures d'absence
        $seuilHeures    = $stats['seuil_heures'];
        $heuresSemestre = $stats['heures_semestre'];

        // Alerte préventive heures
        if ($heuresSemestre >= ($seuilHeures * 2 / 3) && $heuresSemestre < $seuilHeures) {
            $notificationService->envoyer(
                $presence['etudiant_id'],
                'Alerte heures d\'absence',
                "Vous avez {$heuresSemestre}h d'absence ce semestre. Seuil maximum : {$seuilHeures}h.",
                'absence',
                $ecole_id,
                ['heures_semestre' => $heuresSemestre, 'seuil_heures' => $seuilHeures]
            );
        }

        // Seuil atteint → exclusion sessions 1 ET 2
        if ($heuresSemestre >= $seuilHeures) {
            $notificationService->envoyer(
                $presence['etudiant_id'],
                'Exclusion sessions 1 & 2',
                "Vous avez dépassé {$seuilHeures}h d'absence. Vous êtes exclu des sessions 1 ET 2.",
                'absence',
                $ecole_id,
                ['heures_semestre' => $heuresSemestre, 'seuil_heures' => $seuilHeures]
            );
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Présences enregistrées avec succès.',
            'data'    => $resultats,
        ]);
    }

    /**
     * Justifier une absence.
     * Enseignant ou Admin uniquement.
     */
    public function justifier(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user    = $request->user();
        $absence = Absence::where('ecole_id', $ecole_id)->findOrFail($id);

        if (!$user->isAdmin() && !$user->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        if ($absence->present) {
            return response()->json([
                'success' => false,
                'message' => 'Cet étudiant était présent, pas d\'absence à justifier.',
            ], 422);
        }

        $validated = $request->validate([
            'type_justification' => 'required|in:permission,justificatif',
            'observation'        => 'nullable|string|max:500',
        ]);

        // Vérifier délai 72h pour justificatif (pas pour permission)
        if ($validated['type_justification'] === 'justificatif') {
            if ($absence->delaiJustificatifDepasse()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Le délai de 72h pour soumettre un justificatif est dépassé.',
                ], 422);
            }
        }

        $absence->update([
            'justifiee'          => true,
            'type_justification' => $validated['type_justification'],
            'date_justification' => now(),
            'justifie_par'       => $user->id,
            'observation'        => $validated['observation'] ?? $absence->observation,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Absence justifiée avec succès.',
            'data'    => $absence->fresh(['etudiant', 'justifiePar']),
        ]);
    }

    /**
     * Lister les absences d'un étudiant.
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $etudiant_id = $user->isEtudiant()
            ? $user->id
            : $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'etudiant_id est requis.',
            ], 422);
        }

        $query = Absence::with(['cours.ecue.ue', 'justifiePar'])
            ->where('ecole_id', $ecole_id)
            ->where('etudiant_id', $etudiant_id)
            ->where('present', false);

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
            $validated['etudiant_id'],
            $validated['ecue_id'],
            $validated['semestre_id']
        );

        return response()->json([
            'success' => true,
            'data'    => $statut,
        ]);
    }

    /**
     * Lister les présences d'un cours.
     */
    public function presencesCours(Request $request, int $ecole_id, int $cours_id): JsonResponse
    {
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($cours_id);

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