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
        $query = Cours::with(['matiere', 'enseignant', 'salle', 'classe.filiere'])
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
        if ($request->filled('semestre')) {
            $query->where('semestre', $request->semestre);
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
            'matiere', 'enseignant', 'salle',
            'classe.filiere', 'classe.etudiants',
        ])->where('ecole_id', $ecole_id)->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $cours,
        ]);
    }

    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'matiere_id'       => 'required|exists:matieres,id',
            'enseignant_id'    => 'required|exists:users,id',
            'salle_id'         => 'required|exists:salles,id',
            'classe_id'        => 'required|exists:classes,id',
            'date_cours'       => 'required|date|after_or_equal:today',
            'heure_debut'      => 'required|date_format:H:i',
            'heure_fin'        => 'required|date_format:H:i|after:heure_debut',
            'semestre'         => 'required|in:S1,S2',
            'annee_academique' => 'required|string|max:10',
            'notes'            => 'nullable|string',
        ]);

        $enseignant = User::findOrFail($validated['enseignant_id']);
        if (!$enseignant->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => "L'utilisateur sélectionné n'est pas un enseignant.",
            ], 422);
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

        $cours->load(['matiere', 'enseignant', 'salle', 'classe']);

        return response()->json([
            'success' => true,
            'message' => 'Cours programmé avec succès.',
            'data'    => $cours,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($id);

        if ($cours->statut === 'termine') {
            return response()->json([
                'success' => false,
                'message' => 'Un cours terminé ne peut plus être modifié.',
            ], 422);
        }

        $validated = $request->validate([
            'matiere_id'       => 'sometimes|exists:matieres,id',
            'enseignant_id'    => 'sometimes|exists:users,id',
            'salle_id'         => 'sometimes|exists:salles,id',
            'classe_id'        => 'sometimes|exists:classes,id',
            'date_cours'       => 'sometimes|date',
            'heure_debut'      => 'sometimes|date_format:H:i',
            'heure_fin'        => 'sometimes|date_format:H:i|after:heure_debut',
            'statut'           => 'sometimes|in:planifie,confirme,annule,reporte,termine',
            'motif_annulation' => 'nullable|string',
            'notes'            => 'nullable|string',
            'semestre'         => 'sometimes|in:S1,S2',
            'annee_academique' => 'sometimes|string|max:10',
        ]);

        $conflits = $this->verifierConflits(
            $ecole_id,
            $validated['date_cours']    ?? ($cours->date_cours instanceof \Carbon\Carbon ? ($cours->date_cours instanceof \Carbon\Carbon ? $cours->date_cours->toDateString() : $cours->date_cours) : $cours->date_cours),
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

        $cours->update($validated);
        $cours->load(['matiere', 'enseignant', 'salle', 'classe']);

        return response()->json([
            'success' => true,
            'message' => 'Cours mis à jour avec succès.',
            'data'    => $cours,
        ]);
    }

    public function destroy(int $ecole_id, int $id): JsonResponse
    {
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

        $query = Cours::with(['matiere', 'enseignant', 'salle', 'classe'])
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

        return response()->json([
            'success'         => true,
            'semaine_debut'   => $debut,
            'semaine_fin'     => $fin,
            'emploi_du_temps' => $cours,
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
            'data'    => $cours->fresh(['matiere', 'enseignant', 'salle', 'classe']),
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
