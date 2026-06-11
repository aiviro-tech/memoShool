<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EcoleConfig;
use App\Models\EcheanceClasse;
use App\Models\Classe;
use App\Models\MembreEcole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EcoleConfigController extends Controller
{
    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS PRIVÉS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Vérifie que l'utilisateur connecté est admin de l'école donnée.
     * Retourne null si OK, retourne une JsonResponse d'erreur sinon.
     */
    private function verifierAdmin(Request $request, int $ecole_id): ?JsonResponse
    {
        $user = $request->user();

        // Super-admin : accès total
        if ($user->role === 'super_admin') {
            return null;
        }

        // Vérifier que l'utilisateur est admin dans CETTE école
        $membre = MembreEcole::where('user_id', $user->id)
            ->where('ecole_id', $ecole_id)
            ->where('statut', 'actif')
            ->first();

        if (!$membre || !in_array($membre->role, ['admin'])) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé. Seuls les administrateurs de cette école peuvent modifier sa configuration.',
            ], 403);
        }

        return null;
    }

    /**
     * Retourne la config avec les valeurs par défaut si elle n'existe pas encore.
     */
    private function configAvecDefauts(int $ecole_id): array
    {
        $config = EcoleConfig::where('ecole_id', $ecole_id)->first();

        if ($config) {
            return $config->toArray();
        }

        // Valeurs par défaut correspondant exactement à la migration
        return [
            'ecole_id'                       => $ecole_id,
            'poids_cc'                       => 40,
            'poids_examen'                   => 60,
            'note_minimale_examen'           => '5.00',
            'moyenne_validation_ue'          => '10.00',
            'rattrapage_note_100_pourcent'   => true,
            'credits_par_semestre'           => 30,
            'seuil_enjambement_pourcent'     => 80,
            'nombre_sessions'                => 2,
            'absences_max_par_ecue'          => 3,
            'absences_max_par_semestre'      => 10,
            'heures_absence_exclusion_s1_s2' => 150,
            'created_at'                     => null,
            'updated_at'                     => null,
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 1 + 2 — Configuration pédagogique & assiduité
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * GET /api/ecoles/{ecole_id}/config
     * Retourne la config (ou les valeurs par défaut si jamais configurée).
     */
    public function show(Request $request, int $ecole_id): JsonResponse
    {
        return response()->json([
            'success'         => true,
            'data'            => $this->configAvecDefauts($ecole_id),
            'est_configuree'  => EcoleConfig::where('ecole_id', $ecole_id)->exists(),
        ]);
    }

    /**
     * POST /api/ecoles/{ecole_id}/config
     * Crée ou met à jour la configuration pédagogique (sections 1 et 2).
     * Accessible uniquement aux admins de l'école.
     */
    public function upsert(Request $request, int $ecole_id): JsonResponse
    {
        // Vérification des droits
        $erreur = $this->verifierAdmin($request, $ecole_id);
        if ($erreur) return $erreur;

        $validated = $request->validate([
            // ── Section 1 — Calcul des notes ─────────────────────────────
            'poids_cc'                       => 'sometimes|integer|min:0|max:100',
            'poids_examen'                   => 'sometimes|integer|min:0|max:100',
            'note_minimale_examen'           => 'sometimes|numeric|min:0|max:20',
            'moyenne_validation_ue'          => 'sometimes|numeric|min:0|max:20',
            'rattrapage_note_100_pourcent'   => 'sometimes|boolean',

            // ── Section 1 — Crédits & progression ────────────────────────
            'credits_par_semestre'           => 'sometimes|integer|min:1|max:60',
            'seuil_enjambement_pourcent'     => 'sometimes|integer|min:0|max:100',
            'nombre_sessions'                => 'sometimes|integer|min:1|max:3',

            // ── Section 2 — Assiduité ─────────────────────────────────────
            'absences_max_par_ecue'          => 'sometimes|integer|min:0|max:50',
            'absences_max_par_semestre'      => 'sometimes|integer|min:0|max:200',
            'heures_absence_exclusion_s1_s2' => 'sometimes|integer|min:0|max:1000',
        ], [
            // Messages d'erreur en français
            'poids_cc.integer'                     => 'Le poids CC doit être un entier.',
            'poids_cc.min'                         => 'Le poids CC ne peut pas être négatif.',
            'poids_cc.max'                         => 'Le poids CC ne peut pas dépasser 100.',
            'poids_examen.integer'                 => 'Le poids examen doit être un entier.',
            'poids_examen.min'                     => 'Le poids examen ne peut pas être négatif.',
            'poids_examen.max'                     => 'Le poids examen ne peut pas dépasser 100.',
            'note_minimale_examen.numeric'         => 'La note minimale doit être un nombre.',
            'note_minimale_examen.min'             => 'La note minimale ne peut pas être négative.',
            'note_minimale_examen.max'             => 'La note minimale ne peut pas dépasser 20.',
            'moyenne_validation_ue.numeric'        => 'La moyenne de validation doit être un nombre.',
            'moyenne_validation_ue.min'            => 'La moyenne de validation ne peut pas être négative.',
            'moyenne_validation_ue.max'            => 'La moyenne de validation ne peut pas dépasser 20.',
            'credits_par_semestre.min'             => 'Le nombre de crédits par semestre doit être au moins 1.',
            'credits_par_semestre.max'             => 'Le nombre de crédits par semestre ne peut pas dépasser 60.',
            'nombre_sessions.min'                  => 'Le nombre de sessions doit être au moins 1.',
            'nombre_sessions.max'                  => 'Le nombre de sessions ne peut pas dépasser 3.',
            'seuil_enjambement_pourcent.min'       => 'Le seuil d\'enjambement ne peut pas être négatif.',
            'seuil_enjambement_pourcent.max'       => 'Le seuil d\'enjambement ne peut pas dépasser 100.',
        ]);

        // ── Règle métier : poids_cc + poids_examen = 100 ─────────────────────
        // On vérifie uniquement si les deux sont fournis ensemble
        $poidsCC     = $validated['poids_cc']     ?? null;
        $poidsExamen = $validated['poids_examen'] ?? null;

        if ($poidsCC !== null && $poidsExamen !== null) {
            if ($poidsCC + $poidsExamen !== 100) {
                return response()->json([
                    'success' => false,
                    'message' => 'La somme du poids CC et du poids examen doit être égale à 100%.',
                    'errors'  => [
                        'poids_cc'     => ['La somme poids_cc + poids_examen doit être égale à 100.'],
                        'poids_examen' => ['La somme poids_cc + poids_examen doit être égale à 100.'],
                    ],
                ], 422);
            }
        }

        // Si un seul est fourni, on vérifie avec la valeur déjà en base
        if ($poidsCC !== null && $poidsExamen === null) {
            $configExistante = EcoleConfig::where('ecole_id', $ecole_id)->first();
            $poidsExamenActuel = $configExistante?->poids_examen ?? 60;
            if ($poidsCC + $poidsExamenActuel !== 100) {
                return response()->json([
                    'success' => false,
                    'message' => "Attention : poids_cc ($poidsCC) + poids_examen actuel ($poidsExamenActuel) ≠ 100. Envoyez les deux valeurs ensemble.",
                ], 422);
            }
        }

        if ($poidsExamen !== null && $poidsCC === null) {
            $configExistante = EcoleConfig::where('ecole_id', $ecole_id)->first();
            $poidsccActuel = $configExistante?->poids_cc ?? 40;
            if ($poidsccActuel + $poidsExamen !== 100) {
                return response()->json([
                    'success' => false,
                    'message' => "Attention : poids_cc actuel ($poidsccActuel) + poids_examen ($poidsExamen) ≠ 100. Envoyez les deux valeurs ensemble.",
                ], 422);
            }
        }

        // ── Règle métier : note_minimale_examen <= moyenne_validation_ue ─────
        $noteMin  = $validated['note_minimale_examen']  ?? null;
        $moyenneV = $validated['moyenne_validation_ue'] ?? null;

        if ($noteMin !== null && $moyenneV !== null) {
            if ($noteMin > $moyenneV) {
                return response()->json([
                    'success' => false,
                    'message' => 'La note minimale à l\'examen ne peut pas être supérieure à la moyenne de validation de l\'UE.',
                ], 422);
            }
        }

        // ── Sauvegarde ────────────────────────────────────────────────────────
        $config = EcoleConfig::updateOrCreate(
            ['ecole_id' => $ecole_id],
            $validated
        );

        return response()->json([
            'success' => true,
            'message' => 'Configuration pédagogique mise à jour avec succès.',
            'data'    => $config->fresh(),
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 3 — Échéances de scolarité par classe
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * GET /api/ecoles/{ecole_id}/classes/{classe_id}/echeances
     * Retourne les échéances d'une classe.
     */
    public function showEcheances(int $ecole_id, int $classe_id): JsonResponse
    {
        // Vérifier que la classe appartient à l'école
        $classe = Classe::where('id', $classe_id)
            ->where('ecole_id', $ecole_id)
            ->firstOrFail();

        $echeances = EcheanceClasse::where('classe_id', $classe_id)
            ->orderBy('numero')
            ->get();

        return response()->json([
            'success'   => true,
            'classe'    => [
                'id'  => $classe->id,
                'nom' => $classe->nom,
            ],
            'data'      => $echeances,
            'total'     => $echeances->count(),
            'montant_total' => $echeances->sum('montant'),
        ]);
    }

    /**
     * POST /api/ecoles/{ecole_id}/classes/{classe_id}/echeances
     * Crée ou remplace toutes les échéances d'une classe.
     * Accessible uniquement aux admins de l'école.
     */
    public function upsertEcheances(Request $request, int $ecole_id, int $classe_id): JsonResponse
    {
        // Vérification des droits
        $erreur = $this->verifierAdmin($request, $ecole_id);
        if ($erreur) return $erreur;

        // Vérifier que la classe appartient à l'école
        $classe = Classe::where('id', $classe_id)
            ->where('ecole_id', $ecole_id)
            ->firstOrFail();

        $validated = $request->validate([
            'echeances'               => 'required|array|min:1|max:12',
            'echeances.*.numero'      => 'required|integer|min:1|max:12',
            'echeances.*.montant'     => 'required|numeric|min:0',
            'echeances.*.date_limite' => 'required|date|after_or_equal:today',
            'echeances.*.libelle'     => 'nullable|string|max:100',
        ], [
            'echeances.required'              => 'La liste des échéances est obligatoire.',
            'echeances.array'                 => 'Les échéances doivent être un tableau.',
            'echeances.min'                   => 'Il faut au moins une échéance.',
            'echeances.max'                   => 'Il ne peut pas y avoir plus de 12 échéances.',
            'echeances.*.numero.required'     => 'Le numéro de l\'échéance est obligatoire.',
            'echeances.*.numero.min'          => 'Le numéro d\'échéance doit être au moins 1.',
            'echeances.*.montant.required'    => 'Le montant est obligatoire.',
            'echeances.*.montant.min'         => 'Le montant ne peut pas être négatif.',
            'echeances.*.date_limite.required'=> 'La date limite est obligatoire.',
            'echeances.*.date_limite.date'    => 'La date limite doit être une date valide.',
            'echeances.*.date_limite.after_or_equal' => 'La date limite ne peut pas être dans le passé.',
        ]);

        // ── Vérifier les numéros d'échéances uniques ──────────────────────────
        $numeros = array_column($validated['echeances'], 'numero');
        if (count($numeros) !== count(array_unique($numeros))) {
            return response()->json([
                'success' => false,
                'message' => 'Chaque échéance doit avoir un numéro unique.',
            ], 422);
        }

        // ── Vérifier que les dates sont ordonnées (optionnel mais recommandé) ──
        $echeancesTriees = collect($validated['echeances'])->sortBy('numero')->values();
        $dates = $echeancesTriees->pluck('date_limite')->toArray();
        for ($i = 1; $i < count($dates); $i++) {
            if ($dates[$i] < $dates[$i - 1]) {
                return response()->json([
                    'success' => false,
                    'message' => "La date de l'échéance {$echeancesTriees[$i]['numero']} doit être postérieure à l'échéance précédente.",
                ], 422);
            }
        }

        // ── Remplacer toutes les échéances existantes ─────────────────────────
        EcheanceClasse::where('classe_id', $classe_id)->delete();

        $nouvelles = $echeancesTriees->map(fn($e) => [
            'classe_id'   => $classe_id,
            'numero'      => $e['numero'],
            'montant'     => $e['montant'],
            'date_limite' => $e['date_limite'],
            'libelle'     => $e['libelle'] ?? "Tranche {$e['numero']}",
            'created_at'  => now(),
            'updated_at'  => now(),
        ])->toArray();

        EcheanceClasse::insert($nouvelles);

        $echeancesCreees = EcheanceClasse::where('classe_id', $classe_id)
            ->orderBy('numero')
            ->get();

        return response()->json([
            'success'       => true,
            'message'       => "Échéances de la classe « {$classe->nom} » mises à jour avec succès.",
            'classe'        => [
                'id'  => $classe->id,
                'nom' => $classe->nom,
            ],
            'data'          => $echeancesCreees,
            'total'         => $echeancesCreees->count(),
            'montant_total' => $echeancesCreees->sum('montant'),
        ]);
    }

    /**
     * DELETE /api/ecoles/{ecole_id}/classes/{classe_id}/echeances
     * Supprime toutes les échéances d'une classe.
     */
    public function deleteEcheances(Request $request, int $ecole_id, int $classe_id): JsonResponse
    {
        $erreur = $this->verifierAdmin($request, $ecole_id);
        if ($erreur) return $erreur;

        $classe = Classe::where('id', $classe_id)
            ->where('ecole_id', $ecole_id)
            ->firstOrFail();

        $nb = EcheanceClasse::where('classe_id', $classe_id)->delete();

        return response()->json([
            'success' => true,
            'message' => "$nb échéance(s) supprimée(s) pour la classe « {$classe->nom} ».",
        ]);
    }
}