<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Inscription;
use App\Models\Classe;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InscriptionController extends Controller
{
    // ──────────────────────────────────────────────────────────
    // LISTE
    // Admin → toutes les inscriptions de l'école
    // Étudiant → seulement ses propres inscriptions
    // ──────────────────────────────────────────────────────────
    public function index(Request $request, $ecole_id): JsonResponse
    {
        $user = $request->user();

        $query = Inscription::with(['etudiant', 'classe'])
            ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id));

        if ($user->isEtudiant()) {
            $query->where('etudiant_id', $user->id);
        }

        if ($request->filled('statut')) {
            $query->where('statut', $request->statut);
        }

        if ($request->filled('classe_id')) {
            $query->where('classe_id', $request->classe_id);
        }

        $inscriptions = $query->latest()->get();

        return response()->json([
            'success' => true,
            'data'    => $inscriptions,
            'total'   => $inscriptions->count(),
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // CRÉER UNE INSCRIPTION
    // ──────────────────────────────────────────────────────────
    public function store(Request $request, $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'classe_id'        => 'required|integer|exists:classes,id',
            'annee_academique' => 'required|string|max:9',
            'etudiant_id'      => 'nullable|integer|exists:users,id',
        ]);

        $classe = Classe::where('id', $validated['classe_id'])
            ->where('ecole_id', $ecole_id)
            ->first();

        if (!$classe) {
            return response()->json([
                'success' => false,
                'message' => "Cette classe n'appartient pas à cette école.",
            ], 422);
        }

        if ($user->isAdmin()) {
            if (empty($validated['etudiant_id'])) {
                return response()->json([
                    'success' => false,
                    'message' => "En tant qu'administrateur, vous devez spécifier l'étudiant à inscrire (etudiant_id).",
                ], 422);
            }
            $etudiantId = $validated['etudiant_id'];
            $etudiant = User::find($etudiantId);
            if (!$etudiant || !$etudiant->isEtudiant()) {
                return response()->json([
                    'success' => false,
                    'message' => "L'utilisateur spécifié n'est pas un étudiant.",
                ], 422);
            }
        } elseif ($user->isEtudiant()) {
            $etudiantId = $user->id;
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les étudiants ou les administrateurs peuvent créer une inscription.',
            ], 403);
        }

        $existe = Inscription::where('etudiant_id', $etudiantId)
            ->where('classe_id', $classe->id)
            ->where('annee_academique', $validated['annee_academique'])
            ->whereIn('statut', ['soumise', 'validee'])
            ->exists();

        if ($existe) {
            return response()->json([
                'success' => false,
                'message' => 'Cet étudiant a déjà une inscription active dans cette classe pour cette année académique.',
            ], 422);
        }

        $statut = $user->isAdmin() ? 'validee' : 'soumise';

        $inscription = Inscription::create([
            'etudiant_id'      => $etudiantId,
            'classe_id'        => $classe->id,
            'annee_academique' => $validated['annee_academique'],
            'date_inscription' => now()->toDateString(),
            'statut'           => $statut,
        ]);

        if ($statut === 'validee') {
            $this->ajouterEtudiantDansClasse($classe, $etudiantId, $validated['annee_academique']);
        }

        return response()->json([
            'success' => true,
            'message' => $statut === 'validee'
                ? 'Étudiant inscrit et validé avec succès.'
                : "Inscription soumise avec succès. En attente de validation.",
            'data'    => $inscription->load(['etudiant', 'classe']),
        ], 201);
    }

    // ──────────────────────────────────────────────────────────
    // VALIDER (admin uniquement)
    // ──────────────────────────────────────────────────────────
    public function valider(Request $request, $ecole_id, $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent valider une inscription.',
            ], 403);
        }

        $inscription = Inscription::with(['etudiant', 'classe'])
            ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
            ->find($id);

        if (!$inscription) {
            return response()->json([
                'success' => false,
                'message' => 'Inscription introuvable.',
            ], 404);
        }

        if ($inscription->statut === 'validee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette inscription est déjà validée.',
            ], 422);
        }

        $inscription->update(['statut' => 'validee']);

        $this->ajouterEtudiantDansClasse(
            $inscription->classe,
            $inscription->etudiant_id,
            $inscription->annee_academique
        );

        return response()->json([
            'success' => true,
            'message' => "Inscription validée avec succès.",
            'data'    => $inscription->fresh(['etudiant', 'classe']),
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // REJETER (admin uniquement)
    // ──────────────────────────────────────────────────────────
    public function rejeter(Request $request, $ecole_id, $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent rejeter une inscription.',
            ], 403);
        }

        $inscription = Inscription::whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
            ->find($id);

        if (!$inscription) {
            return response()->json([
                'success' => false,
                'message' => 'Inscription introuvable.',
            ], 404);
        }

        $request->validate([
            'motif_rejet' => 'required|string|max:255',
        ]);

        $inscription->update([
            'statut'      => 'rejetee',
            'motif_rejet' => $request->motif_rejet,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Inscription rejetée.',
            'data'    => $inscription->fresh(['etudiant', 'classe']),
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // SUPPRIMER (admin uniquement) ← NOUVEAU
    // ──────────────────────────────────────────────────────────
    public function destroy(Request $request, $ecole_id, $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent supprimer une inscription.',
            ], 403);
        }

        $inscription = Inscription::with('classe')
            ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
            ->find($id);

        if (!$inscription) {
            return response()->json([
                'success' => false,
                'message' => 'Inscription introuvable.',
            ], 404);
        }

        // Si l'inscription était validée, retirer l'étudiant de la table pivot
        if ($inscription->statut === 'validee') {
            $inscription->classe->etudiants()->detach($inscription->etudiant_id);
        }

        $inscription->delete();

        return response()->json([
            'success' => true,
            'message' => 'Inscription supprimée avec succès.',
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // DÉTAIL
    // ──────────────────────────────────────────────────────────
    public function show(Request $request, $ecole_id, $id): JsonResponse
    {
        $user = $request->user();

        $query = Inscription::with(['etudiant', 'classe.typesFrais', 'paiements'])
            ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id));

        if ($user->isEtudiant()) {
            $query->where('etudiant_id', $user->id);
        }

        $inscription = $query->find($id);

        if (!$inscription) {
            return response()->json([
                'success' => false,
                'message' => 'Inscription introuvable.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'inscription'   => $inscription,
                'total_paye'    => $inscription->totalPaye(),
                'solde_restant' => $inscription->soldeRestant(),
            ],
        ]);
    }

    // ──────────────────────────────────────────────────────────
    // Méthode privée : synchroniser la table pivot etudiant_classe
    // ──────────────────────────────────────────────────────────
    private function ajouterEtudiantDansClasse(Classe $classe, int $etudiantId, string $anneeAcademique): void
    {
        if (!$classe->etudiants()->where('user_id', $etudiantId)->exists()) {
            $classe->etudiants()->attach($etudiantId, [
                'annee_academique' => $anneeAcademique,
            ]);
        }
    }
}