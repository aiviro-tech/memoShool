<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TypeFrais;
use App\Models\Classe;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TypeFraisController extends Controller
{
    // ── Lister les types de frais d'une classe ────────────────────────────────
    public function index($ecole_id, $classe_id): JsonResponse
    {
        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $typesFrais   = $classe->typesFrais;
        $montantTotal = $typesFrais->where('obligatoire', true)->sum('montant');

        return response()->json([
            'success' => true,
            'data'    => [
                'types_frais'   => $typesFrais,
                'montant_total' => $montantTotal,
            ],
        ]);
    }

    // ── Créer un type de frais ────────────────────────────────────────────────
    public function store(Request $request, $ecole_id, $classe_id): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent gérer les types de frais.',
            ], 403);
        }

        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $validated = $request->validate([
            'libelle'     => 'required|string|max:100',
            'montant'     => 'required|numeric|min:0',
            'obligatoire' => 'boolean',
        ]);

        $typeFrais = $classe->typesFrais()->create($validated);

        // CORRECTION : synchroniser coutScolarite après création
        $this->syncCoutScolarite($classe->id);

        return response()->json([
            'success' => true,
            'message' => 'Type de frais créé avec succès.',
            'data'    => $typeFrais,
        ], 201);
    }

    // ── Modifier un type de frais ─────────────────────────────────────────────
    public function update(Request $request, $ecole_id, $classe_id, $id): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent gérer les types de frais.',
            ], 403);
        }

        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $typeFrais = TypeFrais::where('classe_id', $classe->id)
                              ->findOrFail($id);

        $validated = $request->validate([
            'libelle'     => 'sometimes|string|max:100',
            'montant'     => 'sometimes|numeric|min:0',
            'obligatoire' => 'sometimes|boolean',
        ]);

        $typeFrais->update($validated);

        // CORRECTION : synchroniser coutScolarite après modification
        $this->syncCoutScolarite($classe->id);

        return response()->json([
            'success' => true,
            'message' => 'Type de frais mis à jour.',
            'data'    => $typeFrais->fresh(),
        ]);
    }

    // ── Supprimer un type de frais ────────────────────────────────────────────
    public function destroy(Request $request, $ecole_id, $classe_id, $id): JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent gérer les types de frais.',
            ], 403);
        }

        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $typeFrais = TypeFrais::where('classe_id', $classe->id)
                              ->findOrFail($id);

        $typeFrais->delete();

        // CORRECTION : synchroniser coutScolarite après suppression
        $this->syncCoutScolarite($classe->id);

        return response()->json([
            'success' => true,
            'message' => 'Type de frais supprimé.',
        ]);
    }

    // ── Méthode privée : recalcule et met à jour coutScolarite ───────────────
    //
    // Après chaque ajout / modif / suppression d'un TypeFrais,
    // on recalcule la somme des frais OBLIGATOIRES et on la stocke
    // dans classes.coutScolarite.
    // C'est ce champ que PaiementController utilise en fallback
    // quand types_frais est vide.
    private function syncCoutScolarite(int $classeId): void
    {
        $total = TypeFrais::where('classe_id', $classeId)
                          ->where('obligatoire', true)
                          ->sum('montant');

        Classe::where('id', $classeId)->update(['coutScolarite' => $total]);
    }
}