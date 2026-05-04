<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Inscription;
use App\Models\Classe;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InscriptionController extends Controller
{
    // Lister les inscriptions d'une école
    public function index(Request $request, $ecole_id): JsonResponse
    {
        $query = Inscription::with(['etudiant', 'classe'])
                            ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id));

        if ($request->filled('statut')) {
            $query->where('statut', $request->statut);
        }

        if ($request->filled('classe_id')) {
            $query->where('classe_id', $request->classe_id);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->get(),
        ]);
    }

    // Soumettre une inscription (par l'étudiant)
    public function store(Request $request, $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'classe_id'        => 'required|exists:classes,id',
            'annee_academique' => 'required|string|max:9',
        ]);

        // Vérifier que la classe appartient à l'école
        $classe = Classe::where('id', $validated['classe_id'])
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        // Vérifier que l'utilisateur est un étudiant
        if ($request->user()->role !== 'etudiant') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les étudiants peuvent soumettre une inscription.',
            ], 403);
        }

        // Vérifier qu'il n'existe pas déjà une inscription
        $existe = Inscription::where('etudiant_id', $request->user()->id)
                             ->where('classe_id', $classe->id)
                             ->where('annee_academique', $validated['annee_academique'])
                             ->exists();

        if ($existe) {
            return response()->json([
                'success' => false,
                'message' => 'Vous êtes déjà inscrit dans cette classe pour cette année.',
            ], 422);
        }

        $inscription = Inscription::create([
            'etudiant_id'      => $request->user()->id,
            'classe_id'        => $classe->id,
            'annee_academique' => $validated['annee_academique'],
            'date_inscription' => now(),
            'statut'           => 'soumise',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Inscription soumise avec succès.',
            'data'    => $inscription->load(['etudiant', 'classe']),
        ], 201);
    }

    // Valider une inscription (par le MembreAdministration)
    public function valider($ecole_id, $id): JsonResponse
    {
        $inscription = Inscription::whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
                                  ->findOrFail($id);

        $inscription->update(['statut' => 'validee']);

        return response()->json([
            'success' => true,
            'message' => 'Inscription validée.',
            'data'    => $inscription,
        ]);
    }

    // Rejeter une inscription (par le MembreAdministration)
    public function rejeter(Request $request, $ecole_id, $id): JsonResponse
    {
        $inscription = Inscription::whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
                                  ->findOrFail($id);

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
            'data'    => $inscription,
        ]);
    }

    // Détail d'une inscription avec paiements
    public function show($ecole_id, $id): JsonResponse
    {
        $inscription = Inscription::with(['etudiant', 'classe.typesFrais', 'paiements'])
                                  ->whereHas('classe', fn($q) => $q->where('ecole_id', $ecole_id))
                                  ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => [
                'inscription'   => $inscription,
                'total_paye'    => $inscription->totalPaye(),
                'solde_restant' => $inscription->soldeRestant(),
            ],
        ]);
    }
}