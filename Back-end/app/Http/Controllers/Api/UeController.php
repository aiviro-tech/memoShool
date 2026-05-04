<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ue;
use App\Models\Semestre;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UeController extends Controller
{
    /**
     * Afficher la liste des UE d'une école (via filière → semestre)
     */
    public function index(Request $request, $ecole_id)
    {
        $ues = Ue::whereHas('semestre.filiere', function ($query) use ($ecole_id) {
            $query->where('ecole_id', $ecole_id);
        })
        ->with(['semestre.filiere'])
        ->get();

        return response()->json([
            'success' => true,
            'data' => $ues
        ]);
    }

    /**
     * Créer une nouvelle UE
     */
    public function store(Request $request, $ecole_id)
    {
        $validator = Validator::make($request->all(), [
            'semestre_id'   => 'required|exists:semestres,id',
            'code'          => 'required|string|unique:ues,code',
            'libelle'       => 'required|string|max:255',
            'credits_ects'  => 'required|integer|min:0',
            'description'   => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Vérifier que le semestre appartient bien à cette école (via filière)
        $semestre = Semestre::where('id', $request->semestre_id)
            ->whereHas('filiere', function ($q) use ($ecole_id) {
                $q->where('ecole_id', $ecole_id);
            })->first();

        if (!$semestre) {
            return response()->json([
                'success' => false,
                'message' => 'Semestre non trouvé ou non autorisé pour cette école.'
            ], 403);
        }

        $ue = Ue::create($request->only(['semestre_id', 'code', 'libelle', 'credits_ects', 'description']));

        return response()->json([
            'success' => true,
            'message' => 'UE créée avec succès',
            'data' => $ue->load('semestre')
        ], 201);
    }

    /**
     * Afficher une UE
     */
    public function show($ecole_id, $id)
    {
        $ue = Ue::where('id', $id)
            ->whereHas('semestre.filiere', function ($query) use ($ecole_id) {
                $query->where('ecole_id', $ecole_id);
            })
            ->with('semestre')
            ->first();

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $ue
        ]);
    }

    /**
     * Mettre à jour une UE
     */
    public function update(Request $request, $ecole_id, $id)
    {
        $ue = Ue::where('id', $id)
            ->whereHas('semestre.filiere', function ($query) use ($ecole_id) {
                $query->where('ecole_id', $ecole_id);
            })->first();

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'semestre_id'   => 'sometimes|exists:semestres,id',
            'code'          => 'sometimes|string|unique:ues,code,' . $id,
            'libelle'       => 'sometimes|string|max:255',
            'credits_ects'  => 'sometimes|integer|min:0',
            'description'   => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $ue->update($request->only(['semestre_id', 'code', 'libelle', 'credits_ects', 'description']));

        return response()->json([
            'success' => true,
            'message' => 'UE mise à jour avec succès',
            'data' => $ue->fresh('semestre')
        ]);
    }

    /**
     * Supprimer une UE
     */
    public function destroy($ecole_id, $id)
    {
        $ue = Ue::where('id', $id)
            ->whereHas('semestre.filiere', function ($query) use ($ecole_id) {
                $query->where('ecole_id', $ecole_id);
            })->first();

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée'
            ], 404);
        }

        // Empêcher la suppression si des ECUEs y sont rattachées
        if ($ue->ecues()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer cette UE car des ECUEs y sont rattachées.'
            ], 422);
        }

        $ue->delete();

        return response()->json([
            'success' => true,
            'message' => 'UE supprimée avec succès'
        ]);
    }
}