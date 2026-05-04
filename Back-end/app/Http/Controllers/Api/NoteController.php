<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AutorisationSaisieNote;
use App\Models\Devoir;
use App\Models\Note;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NoteController extends Controller
{
    /**
     * Lister les devoirs d'une ECUE pour une classe.
     * Admin/Enseignant : tous les devoirs
     * Etudiant : devoirs avec ses notes
     */
    public function indexDevoirs(Request $request, int $ecole_id): JsonResponse
    {
        $user  = $request->user();
        $query = Devoir::with(['ecue.ue', 'enseignant', 'classe'])
                       ->where('ecole_id', $ecole_id);

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);
        } elseif ($user->isEtudiant()) {
            $classeIds = $user->classes()->pluck('classes.id');
            $query->whereIn('classe_id', $classeIds);
        }

        if ($request->filled('ecue_id')) {
            $query->where('ecue_id', $request->ecue_id);
        }
        if ($request->filled('classe_id')) {
            $query->where('classe_id', $request->classe_id);
        }
        if ($request->filled('session')) {
            $query->where('session', $request->session);
        }
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        $devoirs = $query->orderBy('date_evaluation')->get();

        return response()->json([
            'success' => true,
            'data'    => $devoirs,
            'total'   => $devoirs->count(),
        ]);
    }

    /**
     * Créer un devoir.
     * Admin ou Enseignant autorisé uniquement.
     */
    public function storeDevoir(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin() && !$user->isEnseignant()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        $validated = $request->validate([
            'ecue_id'          => 'required|exists:ecues,id',
            'classe_id'        => 'required|exists:classes,id',
            'semestre_id'      => 'required|exists:semestres,id',
            'enseignant_id'    => 'sometimes|exists:users,id',
            'titre'            => 'required|string|max:255',
            'type'             => 'required|in:CC,TP,TD,EXAMEN',
            'session'          => 'required|integer|in:1,2',
            'bareme'           => 'required|numeric|min:1|max:100',
            'date_evaluation'  => 'required|date',
            'duree'            => 'nullable|integer|min:1',
            'description'      => 'nullable|string',
        ]);

        // Vérifier que l'ECUE appartient à l'école
        $ecueAppartientEcole = \App\Models\Ecue::where('id', $validated['ecue_id'])
            ->where('ecole_id', $ecole_id)->exists();
        if (!$ecueAppartientEcole) {
            return response()->json([
                'success' => false,
                'message' => "L'ECUE spécifiée n'appartient pas à cette école.",
            ], 403);
        }

        // Un enseignant ne peut créer un devoir que pour ses cours
        if ($user->isEnseignant()) {
            $enseigneCetEcue = \App\Models\Cours::where('ecue_id', $validated['ecue_id'])
                ->where('classe_id', $validated['classe_id'])
                ->where('enseignant_id', $user->id)
                ->exists();
            if (!$enseigneCetEcue) {
                return response()->json([
                    'success' => false,
                    'message' => "Vous n'enseignez pas cette ECUE dans cette classe.",
                ], 403);
            }
        }

        // Un seul EXAMEN par session par ECUE par classe
        if ($validated['type'] === 'EXAMEN') {
            $examenExiste = Devoir::where('ecue_id', $validated['ecue_id'])
                ->where('classe_id', $validated['classe_id'])
                ->where('type', 'EXAMEN')
                ->where('session', $validated['session'])
                ->exists();
            if ($examenExiste) {
                return response()->json([
                    'success' => false,
                    'message' => "Un examen existe déjà pour cette ECUE, cette classe et cette session.",
                ], 422);
            }
        }

        $devoir = Devoir::create([
            ...$validated,
            'ecole_id'     => $ecole_id,
            'enseignant_id' => $validated['enseignant_id'] ?? $user->id,
        ]);

        $devoir->load(['ecue.ue', 'enseignant', 'classe']);

        return response()->json([
            'success' => true,
            'message' => 'Devoir créé avec succès.',
            'data'    => $devoir,
        ], 201);
    }

    /**
     * Saisir les notes d'un devoir.
     * Enseignant autorisé uniquement (middleware note.autorisation).
     */
    public function saisirNotes(Request $request, int $ecole_id, int $devoir_id): JsonResponse
    {
        $user   = $request->user();
        $devoir = Devoir::where('ecole_id', $ecole_id)->findOrFail($devoir_id);

        // Vérifier que l'enseignant est membre actif de l'école
        if ($user->isEnseignant()) {
            $estMembre = \App\Models\MembreEcole::where('user_id', $user->id)
                ->where('ecole_id', $ecole_id)
                ->where('statut', 'actif')
                ->exists();

            if (!$estMembre) {
                return response()->json([
                    'success' => false,
                    'message' => "Vous n'êtes pas membre actif de cette école.",
                ], 403);
            }
        }

        // Un enseignant ne peut saisir que pour ses devoirs
        if ($user->isEnseignant() && $devoir->enseignant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => "Vous ne pouvez saisir des notes que pour vos propres devoirs.",
            ], 403);
        }

        $validated = $request->validate([
            'notes'                => 'required|array|min:1',
            'notes.*.etudiant_id'  => 'required|exists:users,id',
            'notes.*.valeur'       => 'nullable|numeric|min:0|max:' . $devoir->bareme,
            'notes.*.absent'       => 'sometimes|boolean',
            'notes.*.observation'  => 'nullable|string|max:500',
        ]);

        $resultats = [];

        foreach ($validated['notes'] as $noteData) {
            $absent = $noteData['absent'] ?? false;

            $note = Note::updateOrCreate(
                [
                    'devoir_id'   => $devoir_id,
                    'etudiant_id' => $noteData['etudiant_id'],
                ],
                [
                    'ecole_id'    => $ecole_id,
                    'valeur'      => $absent ? 0 : $noteData['valeur'],
                    'absent'      => $absent,
                    'observation' => $noteData['observation'] ?? null,
                ]
            );

            $resultats[] = $note;
        }

        $notificationService = new \App\Services\NotificationService();
        $devoir->load('ecue');

        foreach ($resultats as $note) {
            $notificationService->notifierNoteDisponible(
                $note->etudiant_id,
                $ecole_id,
                $devoir->ecue->nom,
                $note->valeur
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Notes saisies avec succès.',
            'data'    => $resultats,
        ]);
    }

    /**
     * Consulter les notes d'un étudiant pour une ECUE.
     */
    public function notesEtudiant(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $etudiant_id = $user->isEtudiant() ? $user->id : $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'etudiant_id est requis.',
            ], 422);
        }

        $query = Note::with(['devoir.ecue.ue', 'devoir.classe'])
                     ->where('ecole_id', $ecole_id)
                     ->where('etudiant_id', $etudiant_id);

        if ($request->filled('ecue_id')) {
            $query->whereHas('devoir', fn($q) => $q->where('ecue_id', $request->ecue_id));
        }
        if ($request->filled('session')) {
            $query->whereHas('devoir', fn($q) => $q->where('session', $request->session));
        }

        $notes = $query->get();

        return response()->json([
            'success' => true,
            'data'    => $notes,
        ]);
    }

    /**
     * Autoriser un enseignant à saisir des notes (Admin uniquement).
     */
    public function autoriser(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent autoriser la saisie de notes.',
            ], 403);
        }

        $validated = $request->validate([
            'enseignant_id'   => 'required|exists:users,id',
            'semestre_id'     => 'required|exists:semestres,id',
            'date_expiration' => 'nullable|date|after:today',
            'observation'     => 'nullable|string',
        ]);

        $autorisation = AutorisationSaisieNote::updateOrCreate(
            [
                'enseignant_id' => $validated['enseignant_id'],
                'semestre_id'   => $validated['semestre_id'],
                'ecole_id'      => $ecole_id,
            ],
            [
                'autorise_par'     => $user->id,
                'actif'            => true,
                'date_autorisation' => now(),
                'date_expiration'  => $validated['date_expiration'] ?? null,
                'observation'      => $validated['observation'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Autorisation accordée avec succès.',
            'data'    => $autorisation->load(['enseignant', 'semestre']),
        ]);
    }

    /**
     * Révoquer l'autorisation d'un enseignant (Admin uniquement).
     */
    public function revoquer(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent révoquer une autorisation.',
            ], 403);
        }

        $autorisation = AutorisationSaisieNote::where('ecole_id', $ecole_id)->findOrFail($id);
        $autorisation->update(['actif' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Autorisation révoquée avec succès.',
        ]);
    }
}