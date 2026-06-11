<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Filiere;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FiliereController extends Controller
{
    /**
     * Lister toutes les filières d'une école
     */
    public function index(int $ecole_id): JsonResponse
    {
        $filieres = Filiere::where('ecole_id', $ecole_id)
                           ->where('actif', true)
                           ->get();

        return response()->json([
            'success' => true,
            'data'    => $filieres,
        ]);
    }

    /**
     * Créer une filière
     * ✅ CORRECTION : Validation unique avec ecole_id
     */
    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'nom'         => 'required|string|max:100',
            'code'        => 'required|string|max:10|unique:filieres,code,NULL,id,ecole_id,' . $ecole_id,
            'description' => 'nullable|string',
        ]);

        $filiere = Filiere::create([
            'nom'         => $validated['nom'],
            'code'        => strtoupper($validated['code']),
            'description' => $validated['description'] ?? null,
            'ecole_id'    => $ecole_id,
            'actif'       => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Filière créée avec succès.',
            'data'    => $filiere,
        ], 201);
    }

    /**
     * Modifier une filière
     */
    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $filiere = Filiere::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'nom'         => 'sometimes|string|max:100',
            'code'        => "sometimes|string|max:10|unique:filieres,code,{$id},id,ecole_id,{$ecole_id}",
            'description' => 'nullable|string',
            'actif'       => 'sometimes|boolean',
        ]);

        if (isset($validated['code'])) {
            $validated['code'] = strtoupper($validated['code']);
        }

        $filiere->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Filière mise à jour.',
            'data'    => $filiere,
        ]);
    }

    /**
     * Désactiver une filière
     */
    public function destroy(int $ecole_id, int $id): JsonResponse
    {
        $filiere = Filiere::where('ecole_id', $ecole_id)->findOrFail($id);
        $filiere->update(['actif' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Filière désactivée.',
        ]);
    }
}