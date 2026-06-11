<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cours;
use App\Models\Inscription;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CoursController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    // ──────────────────────────────────────────────────────────
    // LISTE
    // ──────────────────────────────────────────────────────────
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user  = $request->user();
        $query = Cours::with(['ecue.ue', 'enseignant', 'salle', 'classe.filiere', 'semestre'])
                      ->where('ecole_id', $ecole_id);

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);

        } elseif ($user->isEtudiant()) {
            $classeIds = Inscription::where('etudiant_id', $user->id)
                ->where('statut', 'validee')
                ->pluck('classe_id');

            if ($classeIds->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'data'    => [],
                    'total'   => 0,
                    'message' => 'Aucune inscription validée trouvée.',
                ]);
            }

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

    // ──────────────────────────────────────────────────────────
    // DÉTAIL
    // ──────────────────────────────────────────────────────────
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

    // ──────────────────────────────────────────────────────────
    // CRÉER — admin uniquement
    // ──────────────────────────────────────────────────────────
    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent créer des cours.',
            ], 403);
        }

        $validated = $request->validate([
            'ecue_id'       => 'required|exists:ecues,id',
            'enseignant_id' => 'required|exists:users,id',
            'salle_id'      => 'required|exists:salles,id',
            'classe_id'     => 'required|exists:classes,id',
            'date_cours'    => 'required|date|after_or_equal:today',
            'heure_debut'   => 'required|date_format:H:i',
            'heure_fin'     => 'required|date_format:H:i|after:heure_debut',
            'semestre_id'   => 'required|exists:semestres,id',
            'notes'         => 'nullable|string',
        ]);

        // Vérifier que l'utilisateur sélectionné est bien un enseignant
        $enseignant = User::findOrFail($validated['enseignant_id']);
        if (!$enseignant->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => "L'utilisateur sélectionné n'est pas un enseignant.",
            ], 422);
        }

        // Vérifier que le semestre appartient à l'école
        $semestreOk = \App\Models\Semestre::where('id', $validated['semestre_id'])
            ->whereHas('filiere', fn($q) => $q->where('ecole_id', $ecole_id))
            ->exists();
        if (!$semestreOk) {
            return response()->json([
                'success' => false,
                'message' => "Le semestre spécifié n'appartient pas à cette école.",
            ], 422);
        }

        // Vérifier ECUE
        if (!\App\Models\Ecue::where('id', $validated['ecue_id'])->where('ecole_id', $ecole_id)->exists()) {
            return response()->json(['success' => false, 'message' => "L'ECUE spécifiée n'appartient pas à cette école."], 422);
        }

        // Vérifier Salle
        if (!\App\Models\Salle::where('id', $validated['salle_id'])->where('ecole_id', $ecole_id)->exists()) {
            return response()->json(['success' => false, 'message' => "La salle spécifiée n'appartient pas à cette école."], 422);
        }

        // Vérifier Classe
        if (!\App\Models\Classe::where('id', $validated['classe_id'])->where('ecole_id', $ecole_id)->exists()) {
            return response()->json(['success' => false, 'message' => "La classe spécifiée n'appartient pas à cette école."], 422);
        }

        // Vérifier que l'enseignant est membre actif de l'école
        if (!\App\Models\MembreEcole::where('user_id', $validated['enseignant_id'])
            ->where('ecole_id', $ecole_id)->where('statut', 'actif')->exists()) {
            return response()->json(['success' => false, 'message' => "L'enseignant n'est pas un membre actif de cette école."], 422);
        }

        // Vérifier les conflits
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
            'created_by' => $user->id,
        ]);

        $cours->load(['ecue.ue', 'enseignant', 'salle', 'classe.etudiants', 'semestre']);

        // ✅ ENVOI DES NOTIFICATIONS
        $etudiantIds = $cours->classe->etudiants->pluck('id')->toArray();
        $userIds     = array_merge($etudiantIds, [$cours->enseignant_id]);

        if (!empty($userIds)) {
            try {
                $this->notificationService->notifierCoursProgramme(
                    $cours->id,
                    $ecole_id,
                    $userIds,
                    false  // false = création, pas modification
                );
            } catch (\Exception $e) {
                \Log::warning('CoursController@store: notification ignorée → ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Cours programmé avec succès.',
            'data'    => $cours,
        ], 201);
    }

    // ──────────────────────────────────────────────────────────
    // MODIFIER — admin uniquement
    // ──────────────────────────────────────────────────────────
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

        // Vérifier les conflits en excluant le cours actuel
        $dateVerif       = $validated['date_cours']    ?? $cours->date_cours->toDateString();
        $heureDebutVerif = $validated['heure_debut']   ?? $cours->heure_debut;
        $heureFinVerif   = $validated['heure_fin']     ?? $cours->heure_fin;
        $salleVerif      = $validated['salle_id']      ?? $cours->salle_id;
        $enseignantVerif = $validated['enseignant_id'] ?? $cours->enseignant_id;
        $classeVerif     = $validated['classe_id']     ?? $cours->classe_id;

        $champsCreneau = ['date_cours', 'heure_debut', 'heure_fin', 'salle_id', 'enseignant_id', 'classe_id'];
        $modifieCreneau = count(array_intersect(array_keys($validated), $champsCreneau)) > 0;

        if ($modifieCreneau) {
            $conflits = $this->verifierConflits(
                $ecole_id,
                $dateVerif,
                $heureDebutVerif,
                $heureFinVerif,
                $salleVerif,
                $enseignantVerif,
                $classeVerif,
                $id
            );

            if (!empty($conflits)) {
                return response()->json([
                    'success'  => false,
                    'message'  => 'Conflits de planning détectés.',
                    'conflits' => $conflits,
                ], 409);
            }
        }

        $cours->update($validated);
        $cours->load(['ecue.ue', 'enseignant', 'salle', 'classe.etudiants', 'semestre']);

        // ✅ ENVOI DES NOTIFICATIONS POUR MODIFICATION
        $etudiantIds = $cours->classe->etudiants->pluck('id')->toArray();
        $userIds     = array_merge($etudiantIds, [$cours->enseignant_id]);

        if (!empty($userIds)) {
            try {
                $this->notificationService->notifierCoursProgramme(
                    $cours->id,
                    $ecole_id,
                    $userIds,
                    true  // true = modification
                );
            } catch (\Exception $e) {
                \Log::warning('CoursController@update: notification ignorée → ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Cours mis à jour avec succès.',
            'data'    => $cours,
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // SUPPRIMER — admin uniquement
    // ──────────────────────────────────────────────────────────
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

        return response()->json(['success' => true, 'message' => 'Cours supprimé.']);
    }

    // ──────────────────────────────────────────────────────────
    // EMPLOI DU TEMPS
    // ──────────────────────────────────────────────────────────
    public function emploiDuTemps(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $semaine = $request->filled('semaine')
            ? Carbon::parse($request->semaine)->startOfWeek()
            : Carbon::now()->startOfWeek();

        $debut = $semaine->toDateString();
        $fin   = $semaine->copy()->endOfWeek()->toDateString();

        $query = Cours::with(['ecue', 'enseignant', 'salle', 'classe.filiere', 'semestre'])
                      ->where('ecole_id', $ecole_id)
                      ->whereBetween('date_cours', [$debut, $fin])
                      ->where('statut', '!=', 'annule')
                      ->orderBy('date_cours')
                      ->orderBy('heure_debut');

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);
        } elseif ($user->isEtudiant()) {
            $classeIds = Inscription::where('etudiant_id', $user->id)
                ->where('statut', 'validee')
                ->pluck('classe_id');

            if ($classeIds->isEmpty()) {
                return response()->json([
                    'success'         => true,
                    'semaine_debut'   => $debut,
                    'semaine_fin'     => $fin,
                    'emploi_du_temps' => [],
                    'message'         => 'Aucune inscription validée.',
                ]);
            }

            $query->whereIn('classe_id', $classeIds);
        }

        $cours = $query->get()->groupBy(fn($c) => $c->date_cours->toDateString());

        $emploiDuTemps = [];
        foreach ($cours as $date => $coursDuJour) {
            $emploiDuTemps[$date] = $coursDuJour->map(fn($c) => [
                'id'               => $c->id,
                'ecue'             => [
                    'id'      => $c->ecue->id,
                    'nom'     => $c->ecue->nom,
                    'code'    => $c->ecue->code,
                    'credits' => $c->ecue->credits,
                ],
                'enseignant'       => [
                    'id'        => $c->enseignant->id,
                    'full_name' => $c->enseignant->full_name,
                ],
                'salle'            => [
                    'id'       => $c->salle->id,
                    'nom'      => $c->salle->nom,
                    'code'     => $c->salle->code,
                    'capacite' => $c->salle->capacite,
                ],
                'classe'           => [
                    'id'      => $c->classe->id,
                    'nom'     => $c->classe->nom,
                    'niveau'  => $c->classe->niveau,
                    'filiere' => ['nom' => $c->classe->filiere->nom],
                ],
                'date_cours'       => $c->date_cours->toDateString(),
                'heure_debut'      => $c->heure_debut,
                'heure_fin'        => $c->heure_fin,
                'statut'           => $c->statut,
                'semestre'         => $c->semestre?->numero,
                'annee_academique' => $c->semestre?->annee_academique,
                'notes'            => $c->notes,
            ])->values()->toArray();
        }

        return response()->json([
            'success'         => true,
            'semaine_debut'   => $debut,
            'semaine_fin'     => $fin,
            'emploi_du_temps' => $emploiDuTemps,
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // CHANGER STATUT — admin uniquement
    // ──────────────────────────────────────────────────────────
    public function changerStatut(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent modifier le statut d\'un cours.',
            ], 403);
        }

        $cours = Cours::where('ecole_id', $ecole_id)->findOrFail($id);

        if ($cours->statut === 'termine') {
            return response()->json([
                'success' => false,
                'message' => 'Le statut d\'un cours terminé ne peut plus être modifié.',
            ], 422);
        }

        $validated = $request->validate([
            'statut'           => 'required|in:planifie,confirme,annule,reporte,termine',
            'motif_annulation' => 'nullable|string|required_if:statut,annule,reporte',
        ]);

        $cours->update($validated);

        // ✅ NOTIFICATION POUR CHANGEMENT DE STATUT
        $etudiantIds = $cours->classe->etudiants->pluck('id')->toArray();
        
        if (!empty($etudiantIds)) {
            try {
                $this->notificationService->notifierStatutCours(
                    $cours->enseignant_id,
                    $ecole_id,
                    $cours->ecue->nom,
                    $cours->date_cours->toDateString(),
                    $validated['statut'],
                    $etudiantIds,
                    $validated['motif_annulation'] ?? ''
                );
            } catch (\Exception $e) {
                \Log::warning('CoursController@changerStatut: notification ignorée → ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => "Statut mis à jour : {$validated['statut']}.",
            'data'    => $cours->fresh(['ecue', 'enseignant', 'salle', 'classe', 'semestre']),
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // Vérification des conflits (méthode privée)
    // ──────────────────────────────────────────────────────────
    private function verifierConflits(
        int $ecole_id, string $date, string $debut, string $fin,
        int $salleId, int $enseignantId, int $classeId, ?int $excludeId = null
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