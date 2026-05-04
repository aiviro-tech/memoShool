<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Semestre;
use App\Models\Filiere;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SemestreController extends Controller
{
    /**
     * Liste des semestres de l'école (possibilité de filtrer par filière)
     */
    public function index(Request $request, $ecole_id)
    {
        $query = Semestre::whereHas('filiere', function ($q) use ($ecole_id) {
            $q->where('ecole_id', $ecole_id);
        })->with('filiere');

        if ($request->filled('filiere_id')) {
            $query->where('filiere_id', $request->filiere_id);
        }

        return response()->json([
            'success' => true,
            'data' => $query->get()
        ]);
    }

    /**
     * Créer un semestre
     */
    public function store(Request $request, $ecole_id)
    {
        $validator = Validator::make($request->all(), [
            'filiere_id'       => 'required|exists:filieres,id',
            'numero'           => 'required|string|max:5',
            'annee_academique' => 'required|string|max:9',
            'date_debut'       => 'nullable|date',
            'date_fin'         => 'nullable|date|after_or_equal:date_debut',
            'description'      => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        // Vérifier que la filière appartient bien à l'école
        $filiere = Filiere::where('id', $request->filiere_id)->where('ecole_id', $ecole_id)->first();
        if (!$filiere) {
            return response()->json(['success' => false, 'message' => 'Filière non trouvée ou non autorisée pour cette école.'], 403);
        }

        // Vérifier l'unicité du semestre
        $exists = Semestre::where('filiere_id', $request->filiere_id)
            ->where('numero', $request->numero)
            ->where('annee_academique', $request->annee_academique)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false, 
                'message' => 'Ce semestre existe déjà pour cette filière et cette année académique.'
            ], 422);
        }

        $semestre = Semestre::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Semestre créé avec succès',
            'data' => $semestre->load('filiere')
        ], 201);
    }

    /**
     * Afficher un semestre
     */
    public function show($ecole_id, $id)
    {
        $semestre = Semestre::whereHas('filiere', function ($q) use ($ecole_id) {
            $q->where('ecole_id', $ecole_id);
        })->with('filiere')->find($id);

        if (!$semestre) {
            return response()->json(['success' => false, 'message' => 'Semestre non trouvé.'], 404);
        }

        return response()->json(['success' => true, 'data' => $semestre]);
    }

    /**
     * Mettre à jour un semestre
     */
    public function update(Request $request, $ecole_id, $id)
    {
        $semestre = Semestre::whereHas('filiere', function ($q) use ($ecole_id) {
            $q->where('ecole_id', $ecole_id);
        })->find($id);

        if (!$semestre) {
            return response()->json(['success' => false, 'message' => 'Semestre non trouvé.'], 404);
        }

        $validator = Validator::make($request->all(), [
            'numero'           => 'sometimes|string|max:5',
            'annee_academique' => 'sometimes|string|max:9',
            'date_debut'       => 'nullable|date',
            'date_fin'         => 'nullable|date|after_or_equal:date_debut',
            'description'      => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        // Si on modifie le numéro ou l'année, il faut vérifier la contrainte d'unicité
        $newNumero = $request->input('numero', $semestre->numero);
        $newAnnee = $request->input('annee_academique', $semestre->annee_academique);

        if ($newNumero !== $semestre->numero || $newAnnee !== $semestre->annee_academique) {
            $exists = Semestre::where('filiere_id', $semestre->filiere_id)
                ->where('numero', $newNumero)
                ->where('annee_academique', $newAnnee)
                ->where('id', '!=', $semestre->id)
                ->exists();

            if ($exists) {
                return response()->json([
                    'success' => false, 
                    'message' => 'Ce semestre existe déjà pour cette filière et cette année académique.'
                ], 422);
            }
        }

        $semestre->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Semestre mis à jour avec succès.',
            'data' => $semestre->fresh('filiere')
        ]);
    }

    /**
     * Supprimer un semestre
     */
    public function destroy($ecole_id, $id)
    {
        $semestre = Semestre::whereHas('filiere', function ($q) use ($ecole_id) {
            $q->where('ecole_id', $ecole_id);
        })->find($id);

        if (!$semestre) {
            return response()->json(['success' => false, 'message' => 'Semestre non trouvé.'], 404);
        }

        if ($semestre->ues()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer ce semestre car des ECUEs y sont rattachées.'
            ], 422);
        }

        $semestre->delete();

        return response()->json(['success' => true, 'message' => 'Semestre supprimé avec succès.']);
    }
}
