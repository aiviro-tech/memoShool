<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Salle;
use App\Models\Cours;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SalleController extends Controller
{
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $query = Salle::where('ecole_id', $ecole_id)
                      ->where('disponible', true);

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->get(),
        ]);
    }

    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $validated = $request->validate([
            'nom'      => 'required|string|max:100',
            'code'     => 'required|string|max:20|unique:salles,code',
            'type'     => 'required|in:amphi,salle,labo,salle_info',
            'capacite' => 'required|integer|min:1',
            'batiment' => 'nullable|string|max:100',
        ]);

        $salle = Salle::create([
            ...$validated,
            'ecole_id' => $ecole_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Salle créée avec succès.',
            'data'    => $salle,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $salle = Salle::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'nom'        => 'sometimes|string|max:100',
            'capacite'   => 'sometimes|integer|min:1',
            'batiment'   => 'nullable|string|max:100',
            'disponible' => 'sometimes|boolean',
        ]);

        $salle->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Salle mise à jour.',
            'data'    => $salle,
        ]);
    }

    public function disponibles(Request $request, int $ecole_id): JsonResponse
    {
        $request->validate([
            'date'        => 'required|date',
            'heure_debut' => 'required|date_format:H:i',
            'heure_fin'   => 'required|date_format:H:i|after:heure_debut',
        ]);

        $sallesOccupees = Cours::where('ecole_id', $ecole_id)
            ->where('date_cours', $request->date)
            ->where('statut', '!=', 'annule')
            ->where(function ($q) use ($request) {
                $q->where('heure_debut', '<', $request->heure_fin)
                  ->where('heure_fin', '>', $request->heure_debut);
            })
            ->pluck('salle_id');

        $sallesLibres = Salle::where('ecole_id', $ecole_id)
            ->where('disponible', true)
            ->whereNotIn('id', $sallesOccupees)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $sallesLibres,
            'total'   => $sallesLibres->count(),
        ]);
    }
}