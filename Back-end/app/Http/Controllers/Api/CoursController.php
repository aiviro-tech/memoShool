<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cours;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CoursController extends Controller
{
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user  = $request->user();
        $query = Cours::with(['ecue.ue', 'enseignant', 'salle', 'classe.filiere', 'semestre'])
                      ->where('ecole_id', $ecole_id);

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);
        } elseif ($user->isEtudiant()) {
            $classeIds = $user->classes()->pluck('classes.id');
            $query->whereIn('classe_id', $classeIds);
        }

        if ($request->filled('date')) {
            $query->where('date_cours', $request->date);
        }
        if ($request->filled('statut')) {
            $query->where('statut', $request->statut);
        }
        if ($request->filled('classe_id')) {
            $query->where('classe_id', $request->classe_id);
        }
        if ($request->filled('semestre_id')) {
            $query->where('semestre_id', $request->semestre_id);
        }

        $cours = $query->orderBy('date_cours')
                       ->orderBy('heure_debut')
                       ->get();

        return response()->json([
            'success' => true,
            'data'    => $cours,
            'total'   => $cours->count(),
        ]);
    }

    public function show(int $ecole_id, int $id): JsonResponse
    {
        $cours = Cours::with([
            'ecue.ue', 'enseignant', 'salle',
            'classe.filiere', 'classe.etudiants', 'semestre'
        ])->where('ecole_id', $ecole_id)->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $cours,
        ]);
    }

    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent creer des cours.',
            ], 403);
        }

        $validated = $request->validate([
            'ecue_id'          => 'required|exists:ecues,id',
            'enseignant_id'    => 'required|exists:users,id',
            'salle_id'         => 'required|exists:salles,id',
            'classe_id'        => 'required|exists:classes,id',
            'date_cours'       => 'required|date|after_or_equal:today',
            'heure_debut'      => 'required|date_format:H:i',
            'heure_fin'        => 'required|date_format:H:i|after:heure_debut',
            'semestre_id'      => 'required|exists:semestres,id',
            'notes'            => 'nullable|string',
        ]);

        $enseignant = User::findOrFail($validated['enseignant_id']);
        if (!$enseignant->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => "L'utilisateur sélectionné n'est pas un enseignant.",
            ], 422);
        }

        $semestreAppartientEcole = \App\Models\Semestre::where('id', $validated['semestre_id'])
            ->whereHas('filiere', function($q) use ($ecole_id) {
                $q->where('ecole_id', $ecole_id);
            })->exists();

        if (!$semestreAppartientEcole) {
            return response()->json([
                'success' => false,
                'message' => "Le semestre spécifié n'appartient pas à cette école.",
            ], 403);
        }

        $ecueAppartientEcole = \App\Models\Ecue::where('id', $validated['ecue_id'])->where('ecole_id', $ecole_id)->exists();
        if (!$ecueAppartientEcole) {
            return response()->json(['success' => false, 'message' => "L'ECUE spécifiée n'appartient pas à cette école."], 403);
        }

        $salleAppartientEcole = \App\Models\Salle::where('id', $validated['salle_id'])->where('ecole_id', $ecole_id)->exists();
        if (!$salleAppartientEcole) {
            return response()->json(['success' => false, 'message' => "La salle spécifiée n'appartient pas à cette école."], 403);
        }

        $classeAppartientEcole = \App\Models\Classe::where('id', $validated['classe_id'])->where('ecole_id', $ecole_id)->exists();
        if (!$classeAppartientEcole) {
            return response()->json(['success' => false, 'message' => "La classe spécifiée n'appartient pas à cette école."], 403);
        }

        $enseignantEstMembre = \App\Models\MembreEcole::where('user_id', $validated['enseignant_id'])
            ->where('ecole_id', $ecole_id)
            ->where('statut', 'actif')
            ->exists();
        if (!$enseignantEstMembre) {
            return response()->json(['success' => false, 'message' => "L'enseignant sélectionné n'est pas un membre actif de cette école."], 403);
        }

        $conflits = $this->verifierConflits(
            $ecole_id,
            $validated['date_cours'],
            $validated['heure_debut'],
            $validated['heure_fin'],
            $validated['salle_id'],
            $validated['enseignant_id'],
            $validated['classe_id']
        );

        if (!empty($conflits)) {
            return response()->json([
                'success'  => false,
                'message'  => 'Conflits de planning détectés.',
                'conflits' => $conflits,
            ], 409);
        }

        $cours = Cours::create([
            ...$validated,
            'ecole_id'   => $ecole_id,
            'statut'     => 'planifie',
            'created_by' => $request->user()->id,
        ]);

        $cours->load(['ecue.ue', 'enseignant', 'salle', 'classe', 'semestre']);

        $notificationService = new \App\Services\NotificationService();

        // Récupérer les étudiants de la classe
        $cours->load('classe.etudiants');
        $etudiantIds = $cours->classe->etudiants->pluck('id')->toArray();

        // Ajouter aussi l'enseignant
        $userIds = array_merge($etudiantIds, [$cours->enseignant_id]);

        $notificationService->notifierCoursProgramme(
            $cours->id,
            $ecole_id,
            $userIds,
            false // pas une modification
        );

        return response()->json([
            'success' => true,
            'message' => 'Cours programmé avec succès.',
            'data'    => $cours,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent modifier des cours.',
            ], 403);
        }

        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($id);

        if ($cours->statut === 'termine') {
            return response()->json([
                'success' => false,
                'message' => 'Un cours terminé ne peut plus être modifié.',
            ], 422);
        }

        $validated = $request->validate([
            'ecue_id'          => 'sometimes|exists:ecues,id',
            'enseignant_id'    => 'sometimes|exists:users,id',
            'salle_id'         => 'sometimes|exists:salles,id',
            'classe_id'        => 'sometimes|exists:classes,id',
            'date_cours'       => 'sometimes|date',
            'heure_debut'      => 'sometimes|date_format:H:i',
            'heure_fin'        => 'sometimes|date_format:H:i|after:heure_debut',
            'statut'           => 'sometimes|in:planifie,confirme,annule,reporte,termine',
            'motif_annulation' => 'nullable|string',
            'notes'            => 'nullable|string',
            'semestre_id'      => 'sometimes|exists:semestres,id',
        ]);

        if (isset($validated['semestre_id']) && $validated['semestre_id'] !== $cours->semestre_id) {
            $semestreAppartientEcole = \App\Models\Semestre::where('id', $validated['semestre_id'])
                ->whereHas('filiere', function($q) use ($ecole_id) {
                    $q->where('ecole_id', $ecole_id);
                })->exists();

            if (!$semestreAppartientEcole) {
                return response()->json([
                    'success' => false,
                    'message' => "Le semestre spécifié n'appartient pas à cette école.",
                ], 403);
            }
        }

        if (isset($validated['ecue_id']) && $validated['ecue_id'] !== $cours->ecue_id) {
            $ecueAppartientEcole = \App\Models\Ecue::where('id', $validated['ecue_id'])->where('ecole_id', $ecole_id)->exists();
            if (!$ecueAppartientEcole) {
                return response()->json(['success' => false, 'message' => "L'ECUE spécifiée n'appartient pas à cette école."], 403);
            }
        }

        if (isset($validated['salle_id']) && $validated['salle_id'] !== $cours->salle_id) {
            $salleAppartientEcole = \App\Models\Salle::where('id', $validated['salle_id'])->where('ecole_id', $ecole_id)->exists();
            if (!$salleAppartientEcole) {
                return response()->json(['success' => false, 'message' => "La salle spécifiée n'appartient pas à cette école."], 403);
            }
        }

        if (isset($validated['classe_id']) && $validated['classe_id'] !== $cours->classe_id) {
            $classeAppartientEcole = \App\Models\Classe::where('id', $validated['classe_id'])->where('ecole_id', $ecole_id)->exists();
            if (!$classeAppartientEcole) {
                return response()->json(['success' => false, 'message' => "La classe spécifiée n'appartient pas à cette école."], 403);
            }
        }

        if (isset($validated['enseignant_id']) && $validated['enseignant_id'] !== $cours->enseignant_id) {
            $enseignantEstMembre = \App\Models\MembreEcole::where('user_id', $validated['enseignant_id'])
                ->where('ecole_id', $ecole_id)
                ->where('statut', 'actif')
                ->exists();
            if (!$enseignantEstMembre) {
                return response()->json(['success' => false, 'message' => "L'enseignant sélectionné n'est pas un membre actif de cette école."], 403);
            }
        }

        $conflits = $this->verifierConflits(
            $ecole_id,
            $validated['date_cours']    ?? ($cours->date_cours instanceof \Carbon\Carbon ? $cours->date_cours->toDateString() : $cours->date_cours),
            $validated['heure_debut']   ?? $cours->heure_debut,
            $validated['heure_fin']     ?? $cours->heure_fin,
            $validated['salle_id']      ?? $cours->salle_id,
            $validated['enseignant_id'] ?? $cours->enseignant_id,
            $validated['classe_id']     ?? $cours->classe_id,
            $id
        );

        if (!empty($conflits) && ($validated['statut'] ?? '') !== 'annule') {
            return response()->json([
                'success'  => false,
                'message'  => 'Conflits de planning détectés.',
                'conflits' => $conflits,
            ], 409);
        }

        $cours->load(['ecue.ue', 'enseignant', 'salle', 'classe', 'semestre']);

        $cours->update($validated);

        $notificationService = new \App\Services\NotificationService();

        $cours->load('classe.etudiants');
        $etudiantIds = $cours->classe->etudiants->pluck('id')->toArray();
        $userIds     = array_merge($etudiantIds, [$cours->enseignant_id]);

        $notificationService->notifierCoursProgramme(
            $cours->id,
            $ecole_id,
            $userIds,
            true // modification
        );

        return response()->json([
            'success' => true,
            'message' => 'Cours mis à jour avec succès.',
            'data'    => $cours,
        ]);
    }

    public function destroy(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent supprimer des cours.',
            ], 403);
        }

        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($id);

        if ($cours->statut === 'termine') {
            return response()->json([
                'success' => false,
                'message' => 'Un cours terminé ne peut pas être supprimé.',
            ], 422);
        }

        $cours->delete();

        return response()->json([
            'success' => true,
            'message' => 'Cours supprimé avec succès.',
        ]);
    }

    public function emploiDuTemps(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $semaine = $request->filled('semaine')
            ? Carbon::parse($request->semaine)->startOfWeek()
            : Carbon::now()->startOfWeek();

        $debut = $semaine->toDateString();
        $fin   = $semaine->copy()->endOfWeek()->toDateString();

        $query = Cours::with(['ecue.ue', 'enseignant', 'salle', 'classe', 'semestre'])
                      ->where('ecole_id', $ecole_id)
                      ->whereBetween('date_cours', [$debut, $fin])
                      ->where('statut', '!=', 'annule')
                      ->orderBy('date_cours')
                      ->orderBy('heure_debut');

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);
        } elseif ($user->isEtudiant()) {
            $classeIds = $user->classes()->pluck('classes.id');
            $query->whereIn('classe_id', $classeIds);
        }

        $cours = $query->get()->groupBy(fn($c) => $c->date_cours->toDateString());

        // Convertir la collection groupée en tableau associatif
        $emploiDuTemps = [];
        foreach ($cours as $date => $coursDuJour) {
            $emploiDuTemps[$date] = $coursDuJour->map(function ($c) {
                return [
                    'id' => $c->id,
                    'ecue' => [
                        'id' => $c->ecue->id,
                        'nom' => $c->ecue->nom,
                        'code' => $c->ecue->code,
                        'credits' => $c->ecue->credits,
                    ],
                    'enseignant' => [
                        'id' => $c->enseignant->id,
                        'first_name' => $c->enseignant->first_name,
                        'last_name' => $c->enseignant->last_name,
                        'full_name' => $c->enseignant->first_name . ' ' . $c->enseignant->last_name,
                    ],
                    'salle' => [
                        'id' => $c->salle->id,
                        'nom' => $c->salle->nom,
                        'code' => $c->salle->code,
                        'capacite' => $c->salle->capacite,
                    ],
                    'classe' => [
                        'id' => $c->classe->id,
                        'nom' => $c->classe->nom,
                        'code' => $c->classe->code,
                        'filiere' => [
                            'id' => $c->classe->filiere->id,
                            'nom' => $c->classe->filiere->nom,
                        ],
                        'niveau' => $c->classe->niveau,
                    ],
                    'date_cours' => $c->date_cours->toDateString(),
                    'heure_debut' => $c->heure_debut,
                    'heure_fin' => $c->heure_fin,
                    'statut' => $c->statut,
                    'semestre' => $c->semestre ? $c->semestre->numero : null,
                    'annee_academique' => $c->semestre ? $c->semestre->annee_academique : null,
                    'notes' => $c->notes,
                    'motif_annulation' => $c->motif_annulation,
                ];
            })->toArray();
        }

        return response()->json([
            'success'         => true,
            'semaine_debut'   => $debut,
            'semaine_fin'     => $fin,
            'emploi_du_temps' => $emploiDuTemps,
        ]);
    }

    public function changerStatut(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'statut'           => 'required|in:planifie,confirme,annule,reporte,termine',
            'motif_annulation' => 'nullable|string|required_if:statut,annule,reporte',
        ]);

        $cours->update($validated);

        return response()->json([
            'success' => true,
            'message' => "Statut mis à jour : {$validated['statut']}.",
            'data'    => $cours->fresh(['ecue.ue', 'enseignant', 'salle', 'classe', 'semestre']),
        ]);
    }

    private function verifierConflits(
        int $ecole_id,
        string $date,
        string $debut,
        string $fin,
        int $salleId,
        int $enseignantId,
        int $classeId,
        ?int $excludeId = null
    ): array {
        $conflits = [];

        $base = Cours::where('ecole_id', $ecole_id)
            ->whereDate('date_cours', $date)
            ->where('statut', '!=', 'annule')
            ->where('heure_debut', '<', $fin)
            ->where('heure_fin', '>', $debut)
            ->when($excludeId, fn($q) => $q->where('id', '!=', $excludeId));

        if ((clone $base)->where('salle_id', $salleId)->exists()) {
            $conflits[] = 'La salle est déjà occupée sur ce créneau.';
        }
        if ((clone $base)->where('enseignant_id', $enseignantId)->exists()) {
            $conflits[] = "L'enseignant a déjà un cours sur ce créneau.";
        }
        if ((clone $base)->where('classe_id', $classeId)->exists()) {
            $conflits[] = "La classe a déjà un cours sur ce créneau.";
        }

        return $conflits;
    }
}
