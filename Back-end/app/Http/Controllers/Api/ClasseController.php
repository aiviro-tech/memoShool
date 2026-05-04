<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classe;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClasseController extends Controller
{
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $query = Classe::with('filiere')
                       ->where('ecole_id', $ecole_id)
                       ->where('actif', true);

        if ($request->filled('filiere_id')) {
            $query->where('filiere_id', $request->filiere_id);
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
            'nom'              => 'required|string|max:100',
            'code'             => 'required|string|max:20|unique:classes,code',
            'niveau'           => 'required|in:L1,L2,L3,M1,M2',
            'filiere_id'       => 'required|exists:filieres,id',
            'annee_academique' => 'required|string|max:10',
            'coutScolarite'    => 'required|numeric|min:0',
        ]);

        $filiereAppartientEcole = \App\Models\Filiere::where('id', $validated['filiere_id'])
            ->where('ecole_id', $ecole_id)
            ->exists();

        if (!$filiereAppartientEcole) {
            return response()->json([
                'success' => false,
                'message' => "La filière spécifiée n'appartient pas à cette école."
            ], 403);
        }

        $classe = Classe::create([
            ...$validated,
            'ecole_id' => $ecole_id,
        ]);

        $classe->load('filiere');

        return response()->json([
            'success' => true,
            'message' => 'Classe créée avec succès.',
            'data'    => $classe,
        ], 201);
    }

    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        // Vérifier que l'utilisateur est un administrateur
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent modifier une classe.',
            ], 403);
        }

        $classe = Classe::where('ecole_id', $ecole_id)->findOrFail($id);

        $validated = $request->validate([
            'nom'           => 'sometimes|string|max:100',
            'actif'         => 'sometimes|boolean',
            'coutScolarite' => 'sometimes|numeric|min:0',
        ]);
        
        $classe->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Classe mise à jour.',
            'data'    => $classe,
        ]);
    }

    public function etudiants(int $ecole_id, int $id): JsonResponse
    {
        $classe = Classe::with('etudiants')
                        ->where('ecole_id', $ecole_id)
                        ->findOrFail($id);

        $etudiants = $classe->etudiants->map(fn($e) => [
            'id'        => $e->id,
            'full_name' => $e->full_name,
            'email'     => $e->email,
        ]);

        return response()->json([
            'success'   => true,
            'classe'    => $classe->nom,
            'etudiants' => $etudiants,
            'total'     => $etudiants->count(),
        ]);
    }
}