<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EcoleConfig;
use App\Models\EcheanceClasse;
use App\Models\Classe;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EcoleConfigController extends Controller
{
    /**
     * Afficher la configuration de l'école.
     */
    public function show(Request $request, int $ecole_id): JsonResponse
    {
        $config = EcoleConfig::where('ecole_id', $ecole_id)->first();

        if (!$config) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune configuration trouvée pour cette école.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $config,
        ]);
    }

    /**
     * Créer ou mettre à jour la configuration pédagogique.
     * Section 1 + Section 2
     */
    public function upsert(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent modifier la configuration.',
            ], 403);
        }

        $validated = $request->validate([
            // Section 1 — Calcul des notes
            'poids_cc'                      => 'sometimes|integer|min:0|max:100',
            'poids_examen'                  => 'sometimes|integer|min:0|max:100',
            'note_minimale_examen'          => 'sometimes|numeric|min:0|max:20',
            'moyenne_validation_ue'         => 'sometimes|numeric|min:0|max:20',
            'rattrapage_note_100_pourcent'  => 'sometimes|boolean',

            // Section 1 — Crédits & progression
            'credits_par_semestre'          => 'sometimes|integer|min:1',
            'seuil_enjambement_pourcent'    => 'sometimes|integer|min:0|max:100',
            'nombre_sessions'               => 'sometimes|integer|min:1|max:3',

            // Section 2 — Absences
            'absences_max_par_ecue'         => 'sometimes|integer|min:1',
            'absences_max_par_semestre'     => 'sometimes|integer|min:1',
            'heures_absence_exclusion_s1_s2'=> 'sometimes|integer|min:1',
        ]);

        // Vérifier que poids_cc + poids_examen = 100
        $poidsCC     = $validated['poids_cc']     ?? null;
        $poidsExamen = $validated['poids_examen'] ?? null;

        if ($poidsCC !== null && $poidsExamen !== null) {
            if ($poidsCC + $poidsExamen !== 100) {
                return response()->json([
                    'success' => false,
                    'message' => 'La somme de poids_cc et poids_examen doit être égale à 100.',
                ], 422);
            }
        }

        $config = EcoleConfig::updateOrCreate(
            ['ecole_id' => $ecole_id],
            $validated
        );

        return response()->json([
            'success' => true,
            'message' => 'Configuration mise à jour avec succès.',
            'data'    => $config,
        ]);
    }

    /**
     * Gérer les échéances d'une classe (Section 3).
     */
    public function upsertEcheances(Request $request, int $ecole_id, int $classe_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent gérer les échéances.',
            ], 403);
        }

        // Vérifier que la classe appartient à l'école
        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $validated = $request->validate([
            'echeances'               => 'required|array|min:1',
            'echeances.*.numero'      => 'required|integer|min:1',
            'echeances.*.montant'     => 'required|numeric|min:0',
            'echeances.*.date_limite' => 'required|date',
            'echeances.*.libelle'     => 'nullable|string|max:100',
        ]);

        // Supprimer les anciennes échéances et recréer
        EcheanceClasse::where('classe_id', $classe_id)->delete();

        $echeances = collect($validated['echeances'])->map(fn($e) => [
            'classe_id'   => $classe_id,
            'numero'      => $e['numero'],
            'montant'     => $e['montant'],
            'date_limite' => $e['date_limite'],
            'libelle'     => $e['libelle'] ?? null,
            'created_at'  => now(),
            'updated_at'  => now(),
        ])->toArray();

        EcheanceClasse::insert($echeances);

        return response()->json([
            'success' => true,
            'message' => 'Échéances mises à jour avec succès.',
            'data'    => EcheanceClasse::where('classe_id', $classe_id)->orderBy('numero')->get(),
        ]);
    }

    /**
     * Afficher les échéances d'une classe.
     */
    public function showEcheances(int $ecole_id, int $classe_id): JsonResponse
    {
        $classe = Classe::where('id', $classe_id)
                        ->where('ecole_id', $ecole_id)
                        ->firstOrFail();

        $echeances = EcheanceClasse::where('classe_id', $classe_id)
                                   ->orderBy('numero')
                                   ->get();

        return response()->json([
            'success' => true,
            'data'    => $echeances,
        ]);
    }
}