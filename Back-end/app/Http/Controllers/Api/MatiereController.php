<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Matiere;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MatiereController extends Controller
{
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $query = Matiere::with('filiere')
                        ->where('ecole_id', $ecole_id)
                        ->where('actif', true);

        if ($request->filled('filiere_id')) {
            $query->where('filiere_id', $request->filiere_id);
        }
        if ($request->filled('niveau')) {
            $query->where('niveau', $request->niveau);
        }
        if ($request->filled('tronc_commun')) {
            $query->whereNull('filiere_id');
        }

        return response()->json([
            'success' => true,
            'data'    => $query->get(),
        ]);
    }

    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'nom'            => 'required|string|max:150',
            'code'           => 'required|string|max:20|unique:matieres,code',
            'credits'        => 'required|integer|min:1',
            'volume_horaire' => 'required|integer|min:1',
            'type'           => 'required|in:CM,TD,TP',
            'niveau'         => 'required|in:L1,L2,L3,M1,M2',
            'filiere_id'     => 'nullable|exists:filieres,id',
            'description'    => 'nullable|string',
        ]);

        $matiere = Matiere::create([
            ...$validated,
            'ecole_id' => $ecole_id,
        ]);

        $matiere->load('filiere');

        return response()->json([
            'success' => true,
            'message' => 'Matière créée avec succès.',
            'data'    => $matiere,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $matiere = Matiere::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'nom'            => 'sometimes|string|max:150',
            'credits'        => 'sometimes|integer|min:1',
            'volume_horaire' => 'sometimes|integer|min:1',
            'description'    => 'nullable|string',
            'actif'          => 'sometimes|boolean',
        ]);

        $matiere->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Matière mise à jour.',
            'data'    => $matiere,
        ]);
    }

    public function destroy(int $ecole_id, int $id): JsonResponse
    {
        $matiere = Matiere::where('ecole_id', $ecole_id)->findOrFail($id);
        $matiere->update(['actif' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Matière désactivée.',
        ]);
    }
}