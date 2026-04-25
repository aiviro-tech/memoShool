<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportCours;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SupportCoursController extends Controller
{
    /**
     * Liste des supports de cours pour une école.
     * Admin : tous les supports
     * Enseignant : ses supports uniquement
     * Etudiant : supports validés des cours de ses classes
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();
        $query = SupportCours::with(['cours.matiere', 'enseignant'])
                             ->where('ecole_id', $ecole_id);

        if ($user->isEnseignant()) {
            $query->where('enseignant_id', $user->id);
        } elseif ($user->isEtudiant()) {
            $classeIds = $user->classes()->pluck('classes.id');
            $query->where('statut', 'valide')
                  ->whereHas('cours', fn($q) => $q->whereIn('classe_id', $classeIds));
        }

        // Filtres optionnels
        if ($request->filled('cours_id')) {
            $query->where('cours_id', $request->cours_id);
        }
        if ($request->filled('statut')) {
            $query->where('statut', $request->statut);
        }

        $supports = $query->orderByDesc('created_at')->get();

        return response()->json([
            'success' => true,
            'data'    => $supports,
            'total'   => $supports->count(),
        ]);
    }

    /**
     * Enseignant dépose un support de cours.
     */
    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isEnseignant() && !$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les enseignants et administrateurs peuvent deposer des supports de cours.',
            ], 403);
        }

        $validated = $request->validate([
            'cours_id'    => 'required|exists:cours,id',
            'titre'       => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'fichier'     => 'required|file|max:20480|mimes:pdf,doc,docx,ppt,pptx,xls,xlsx,jpg,jpeg,png,zip',
        ]);

        $fichier = $request->file('fichier');
        $path = $fichier->store("supports/ecole_{$ecole_id}", 'public');

        $support = SupportCours::create([
            'ecole_id'       => $ecole_id,
            'cours_id'       => $validated['cours_id'],
            'enseignant_id'  => $user->id,
            'titre'          => $validated['titre'],
            'description'    => $validated['description'] ?? null,
            'fichier_path'   => $path,
            'fichier_nom'    => $fichier->getClientOriginalName(),
            'fichier_type'   => $fichier->getClientOriginalExtension(),
            'fichier_taille' => $fichier->getSize(),
            'statut'         => 'en_attente',
        ]);

        $support->load(['cours.matiere', 'enseignant']);

        return response()->json([
            'success' => true,
            'message' => 'Support déposé avec succès. En attente de validation par l\'administration.',
            'data'    => $support,
        ], 201);
    }

    /**
     * Admin valide un support de cours.
     */
    public function valider(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent valider les supports.',
            ], 403);
        }

        $support = SupportCours::where('ecole_id', $ecole_id)->findOrFail($id);

        if (!$support->estEnAttente()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce support a déjà été traité.',
            ], 422);
        }

        $support->update([
            'statut'     => 'valide',
            'valide_par' => $user->id,
            'valide_at'  => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Support validé avec succès.',
            'data'    => $support->fresh(['cours.matiere', 'enseignant', 'validateur']),
        ]);
    }

    /**
     * Admin rejette un support de cours.
     */
    public function rejeter(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent rejeter les supports.',
            ], 403);
        }

        $validated = $request->validate([
            'motif_rejet' => 'required|string|max:500',
        ]);

        $support = SupportCours::where('ecole_id', $ecole_id)->findOrFail($id);

        if (!$support->estEnAttente()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce support a déjà été traité.',
            ], 422);
        }

        $support->update([
            'statut'      => 'rejete',
            'motif_rejet' => $validated['motif_rejet'],
            'valide_par'  => $user->id,
            'valide_at'   => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Support rejeté.',
            'data'    => $support->fresh(['cours.matiere', 'enseignant']),
        ]);
    }

    /**
     * Supprimer un support de cours.
     */
    public function destroy(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user = $request->user();
        $support = SupportCours::where('ecole_id', $ecole_id)->findOrFail($id);

        // Seul l'enseignant propriétaire ou un admin peut supprimer
        if (!$user->isAdmin() && $support->enseignant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas la permission de supprimer ce support.',
            ], 403);
        }

        // Supprimer le fichier du storage
        if (Storage::disk('public')->exists($support->fichier_path)) {
            Storage::disk('public')->delete($support->fichier_path);
        }

        $support->delete();

        return response()->json([
            'success' => true,
            'message' => 'Support supprime avec succes.',
        ]);
    }

    /**
     * Telecharger un support de cours.
     * Admin/Enseignant : tous les supports
     * Etudiant : uniquement les supports valides
     */
    public function download(Request $request, int $ecole_id, int $id)
    {
        $user = $request->user();
        $support = SupportCours::where('ecole_id', $ecole_id)->findOrFail($id);

        // Un etudiant ne peut telecharger que les supports valides
        if ($user->isEtudiant() && $support->statut !== 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Ce support n\'est pas encore disponible au telechargement.',
            ], 403);
        }

        if (!Storage::disk('public')->exists($support->fichier_path)) {
            return response()->json([
                'success' => false,
                'message' => 'Le fichier n\'existe plus sur le serveur.',
            ], 404);
        }

        return Storage::disk('public')->download(
            $support->fichier_path,
            $support->fichier_nom
        );
    }
}
