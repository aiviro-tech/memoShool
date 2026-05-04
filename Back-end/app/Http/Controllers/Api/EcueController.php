<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ecue;
use App\Models\Ue;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EcueController extends Controller
{
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $query = Ecue::with('ue.semestre.filiere')
                        ->where('ecole_id', $ecole_id)
                        ->where('actif', true);

        if ($request->filled('filiere_id')) {
            $query->whereHas('ue.semestre', function ($q) use ($request) {
                $q->where('filiere_id', $request->filiere_id);
            });
        }
        if ($request->filled('ue_id')) {
            $query->where('ue_id', $request->ue_id);
        }
        if ($request->filled('niveau')) {
            $query->where('niveau', $request->niveau);
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
            'code'           => 'required|string|max:20|unique:ecues,code',
            'credits'        => 'required|integer|min:1',
            'volume_horaire' => 'required|integer|min:1',
            'type'           => 'required|in:CM,TD,TP',
            'niveau'         => 'required|in:L1,L2,L3,M1,M2',
            'ue_id'          => 'required|exists:ues,id',
            'description'    => 'nullable|string',
        ]);

        // Vérifier que l'UE appartient bien à cette école
        $ueAppartientEcole = Ue::where('id', $validated['ue_id'])
            ->whereHas('semestre.filiere', function ($q) use ($ecole_id) {
                $q->where('ecole_id', $ecole_id);
            })->exists();

        if (!$ueAppartientEcole) {
            return response()->json([
                'success' => false,
                'message' => "L'UE spécifiée n'appartient pas à cette école."
            ], 403);
        }

        $ecue = Ecue::create([
            ...$validated,
            'ecole_id' => $ecole_id,
        ]);

        $ecue->load('ue.semestre.filiere');

        return response()->json([
            'success' => true,
            'message' => 'ECUE créée avec succès.',
            'data'    => $ecue,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $ecue = Ecue::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'nom'            => 'sometimes|string|max:150',
            'credits'        => 'sometimes|integer|min:1',
            'volume_horaire' => 'sometimes|integer|min:1',
            'description'    => 'nullable|string',
            'ue_id'          => 'sometimes|exists:ues,id',
            'actif'          => 'sometimes|boolean',
        ]);

        if (isset($validated['ue_id']) && $validated['ue_id'] !== $ecue->ue_id) {
            $ueAppartientEcole = Ue::where('id', $validated['ue_id'])
                ->whereHas('semestre.filiere', function ($q) use ($ecole_id) {
                    $q->where('ecole_id', $ecole_id);
                })->exists();

            if (!$ueAppartientEcole) {
                return response()->json([
                    'success' => false,
                    'message' => "L'UE spécifiée n'appartient pas à cette école."
                ], 403);
            }
        }

        $ecue->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'ECUE mise à jour.',
            'data'    => $ecue,
        ]);
    }

    public function destroy(int $ecole_id, int $id): JsonResponse
    {
        $ecue = Ecue::where('ecole_id', $ecole_id)->findOrFail($id);
        $ecue->update(['actif' => false]);

        return response()->json([
            'success' => true,
            'message' => 'ECUE désactivée.',
        ]);
    }
}