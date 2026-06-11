<?php

// ============================================================
// FICHIER : app/Http/Controllers/Api/UeController.php
// ACTION  : Remplace COMPLÈTEMENT ton UeController.php
// CORRECTION PRINCIPALE :
//   La vérification "semestre appartient à l'école" utilisait
//   whereHas('filiere') sur le semestre, ce qui suppose que la
//   relation Semestre→Filiere existe ET que filiere a ecole_id.
//   On sécurise cette vérification et on ajoute des messages
//   d'erreur très clairs pour chaque cas d'échec.
// ============================================================

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ue;
use App\Models\Semestre;
use App\Models\Filiere;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UeController extends Controller
{
    /**
     * Lister les UE d'une école
     */
    public function index(Request $request, $ecole_id): JsonResponse
    {
        // On récupère toutes les UE dont le semestre est lié à cette école
        // via la filière du semestre
        $ues = Ue::with(['semestre.filiere'])
            ->whereHas('semestre', function ($q) use ($ecole_id) {
                $q->whereHas('filiere', function ($q2) use ($ecole_id) {
                    $q2->where('ecole_id', $ecole_id);
                });
            })
            ->when($request->filled('semestre_id'), function ($q) use ($request) {
                $q->where('semestre_id', $request->semestre_id);
            })
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $ues,
            'total'   => $ues->count(),
        ]);
    }

    /**
     * Créer une UE
     *
     * Prérequis côté admin :
     *   1. Une filière doit exister pour cette école
     *   2. Un semestre doit exister rattaché à cette filière
     *   3. Alors seulement on peut créer une UE
     */
    public function store(Request $request, $ecole_id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'semestre_id'  => 'required|integer|exists:semestres,id',
            'code'         => 'required|string|max:50|unique:ues,code',
            'libelle'      => 'required|string|max:255',
            'credits_ects' => 'required|integer|min:0|max:60',
            'description'  => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 422);
        }

        // ── Vérifier que le semestre existe et appartient à cette école ──
        $semestre = Semestre::with('filiere')->find($request->semestre_id);

        if (!$semestre) {
            return response()->json([
                'success' => false,
                'message' => "Semestre introuvable (id: {$request->semestre_id}).",
            ], 422);
        }

        // Vérifier que la filière du semestre existe
        if (!$semestre->filiere) {
            return response()->json([
                'success' => false,
                'message' => "Le semestre \"{$semestre->numero}\" n'est rattaché à aucune filière. "
                           . "Veuillez d'abord créer une filière et un semestre correctement liés à cette école.",
            ], 422);
        }

        // Vérifier que la filière appartient à cette école
        if ((int)$semestre->filiere->ecole_id !== (int)$ecole_id) {
            return response()->json([
                'success' => false,
                'message' => "Le semestre \"{$semestre->numero}\" appartient à la filière \"{$semestre->filiere->nom}\" "
                           . "qui n'est pas rattachée à cette école. "
                           . "Créez d'abord un semestre dans une filière de cette école.",
            ], 422);
        }

        // ── Créer l'UE ──
        $ue = Ue::create([
            'semestre_id'  => $request->semestre_id,
            'code'         => strtoupper(trim($request->code)),
            'libelle'      => trim($request->libelle),
            'credits_ects' => $request->credits_ects,
            'description'  => $request->description,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'UE créée avec succès.',
            'data'    => $ue->load('semestre.filiere'),
        ], 201);
    }

    /**
     * Afficher une UE
     */
    public function show($ecole_id, $id): JsonResponse
    {
        $ue = Ue::with('semestre.filiere')
            ->whereHas('semestre', function ($q) use ($ecole_id) {
                $q->whereHas('filiere', fn($q2) => $q2->where('ecole_id', $ecole_id));
            })
            ->find($id);

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée ou n\'appartient pas à cette école.',
            ], 404);
        }

        return response()->json(['success' => true, 'data' => $ue]);
    }

    /**
     * Modifier une UE
     */
    public function update(Request $request, $ecole_id, $id): JsonResponse
    {
        $ue = Ue::whereHas('semestre', function ($q) use ($ecole_id) {
            $q->whereHas('filiere', fn($q2) => $q2->where('ecole_id', $ecole_id));
        })->find($id);

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'semestre_id'  => 'sometimes|integer|exists:semestres,id',
            'code'         => 'sometimes|string|max:50|unique:ues,code,' . $id,
            'libelle'      => 'sometimes|string|max:255',
            'credits_ects' => 'sometimes|integer|min:0|max:60',
            'description'  => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 422);
        }

        // Si le semestre_id change, re-vérifier qu'il appartient à l'école
        if ($request->filled('semestre_id') && $request->semestre_id != $ue->semestre_id) {
            $semestre = Semestre::with('filiere')->find($request->semestre_id);
            if (!$semestre || !$semestre->filiere || (int)$semestre->filiere->ecole_id !== (int)$ecole_id) {
                return response()->json([
                    'success' => false,
                    'message' => "Le semestre spécifié n'appartient pas à cette école.",
                ], 422);
            }
        }

        $ue->update($request->only(['semestre_id', 'code', 'libelle', 'credits_ects', 'description']));

        return response()->json([
            'success' => true,
            'message' => 'UE mise à jour.',
            'data'    => $ue->fresh('semestre.filiere'),
        ]);
    }

    /**
     * Supprimer une UE
     */
    public function destroy($ecole_id, $id): JsonResponse
    {
        $ue = Ue::whereHas('semestre', function ($q) use ($ecole_id) {
            $q->whereHas('filiere', fn($q2) => $q2->where('ecole_id', $ecole_id));
        })->find($id);

        if (!$ue) {
            return response()->json([
                'success' => false,
                'message' => 'UE non trouvée.',
            ], 404);
        }

        if ($ue->ecues()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer : des ECUEs sont rattachées à cette UE.',
            ], 422);
        }

        $ue->delete();

        return response()->json(['success' => true, 'message' => 'UE supprimée.']);
    }
}