<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Releve;
use App\Services\MoyenneCalculatorService;
use App\Services\ReleveGeneratorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReleveController extends Controller
{
    public function generer(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'etudiant_id' => 'required|exists:users,id',
            'semestre_id' => 'required|exists:semestres,id',
            'classe_id'   => 'required|exists:classes,id',
            'session'     => 'required|integer|in:1,2',
        ]);

        if ($user->isEtudiant() && $user->id !== (int) $validated['etudiant_id']) {
            return response()->json(['success' => false, 'message' => 'Vous ne pouvez générer que votre propre relevé.'], 403);
        }

        try {
            $service  = new ReleveGeneratorService($ecole_id);
            $resultat = $service->generer(
                (int) $validated['etudiant_id'],
                (int) $validated['semestre_id'],
                (int) $validated['classe_id'],
                (int) $validated['session']
            );
            return response()->json(['success' => true, 'message' => 'Relevé généré avec succès.', 'data' => $resultat['releve']], 201);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Erreur : ' . $e->getMessage()], 500);
        }
    }

    public function telecharger(Request $request, int $ecole_id, int $id)
    {
        // CORRECTION : launchUrl() ouvre un lien navigateur sans header Authorization.
        // Laravel redirige vers Route[login] qui n'existe pas en mode API.
        // Solution : accepter le token Sanctum en query parameter ?token=xxx
        $user = $request->user();

        if (!$user) {
            $token = $request->query('token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
            }
            $personalToken = \Laravel\Sanctum\PersonalAccessToken::findToken($token);
            if (!$personalToken || !$personalToken->tokenable) {
                return response()->json(['success' => false, 'message' => 'Token invalide.'], 401);
            }
            $user = $personalToken->tokenable;
        }

        $releve = Releve::where('ecole_id', $ecole_id)->findOrFail($id);

        if ($user->isEtudiant() && $user->id !== (int) $releve->etudiant_id) {
            return response()->json(['success' => false, 'message' => 'Vous ne pouvez télécharger que votre propre relevé.'], 403);
        }

        if (!$releve->fichier_path || !Storage::disk('public')->exists($releve->fichier_path)) {
            return response()->json(['success' => false, 'message' => "Le fichier PDF n'existe pas."], 404);
        }

        return Storage::disk('public')->download(
            $releve->fichier_path,
            "releve_{$releve->etudiant_id}_s{$releve->semestre_id}_session{$releve->session}.pdf"
        );
    }

    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user        = $request->user();
        $etudiant_id = $user->isEtudiant() ? $user->id : (int) $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json(['success' => false, 'message' => 'etudiant_id est requis.'], 422);
        }

        $releves = Releve::with(['semestre', 'classe.filiere'])
            ->where('ecole_id', $ecole_id)
            ->where('etudiant_id', $etudiant_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $releves]);
    }

    public function bilanAnnuel(Request $request, int $ecole_id): JsonResponse
    {
        $user      = $request->user();
        $validated = $request->validate([
            'etudiant_id'    => 'required|exists:users,id',
            'classe_id'      => 'required|exists:classes,id',
            'semestre_ids'   => 'required|array|min:2|max:2',
            'semestre_ids.*' => 'required|exists:semestres,id',
        ]);

        if ($user->isEtudiant() && $user->id !== (int) $validated['etudiant_id']) {
            return response()->json(['success' => false, 'message' => 'Vous ne pouvez consulter que votre propre bilan.'], 403);
        }

        try {
            $service = new MoyenneCalculatorService($ecole_id);
            $bilan   = $service->calculerBilanAnnuel(
                (int) $validated['etudiant_id'],
                (int) $validated['classe_id'],
                array_map('intval', $validated['semestre_ids'])
            );
            return response()->json(['success' => true, 'data' => $bilan]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Erreur : ' . $e->getMessage()], 500);
        }
    }

    /**
     * Moyennes d'un étudiant pour un semestre.
     *
     * CORRECTIONS :
     * 1. (int) cast → résout le 403 "ne pouvez consulter que vos propres moyennes"
     *    ($user->id = int, $validated['etudiant_id'] = string → !== échouait)
     * 2. Reformatage de la réponse pour Flutter (MoyenneSemestreModel)
     * 3. Les ECUE "en_attente" sont affichées comme telles (moyenne = null)
     *    au lieu d'afficher 0.00
     */
    public function moyennesSemestre(Request $request, int $ecole_id): JsonResponse
    {
        $user      = $request->user();
        $validated = $request->validate([
            'etudiant_id' => 'required|exists:users,id',
            'semestre_id' => 'required|exists:semestres,id',
            'classe_id'   => 'required|exists:classes,id',
            'session'     => 'sometimes|integer|in:1,2',
        ]);

        // CORRECTION PRINCIPALE : cast (int) obligatoire
        if ($user->isEtudiant() && $user->id !== (int) $validated['etudiant_id']) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez consulter que vos propres moyennes.',
            ], 403);
        }

        try {
            $service  = new MoyenneCalculatorService($ecole_id);
            $session  = isset($validated['session']) ? (int) $validated['session'] : 1;

            $resultat = $service->calculerMoyenneSemestre(
                (int) $validated['etudiant_id'],
                (int) $validated['semestre_id'],
                (int) $validated['classe_id'],
                $session
            );

            // ── Reformatage pour Flutter (MoyenneSemestreModel.fromJson) ──────
            // calculerMoyenneSemestre retourne les ECUE imbriquées dans les UEs.
            // Flutter attend une liste d'ECUE aplaties avec les bons noms de champs.
            $ecuesApplaties = [];
            $creditsValides = 0;
            $creditsTotal   = 0;

            foreach ($resultat['ues'] as $ue) {
                foreach ($ue['ecues'] as $ecue) {
                    $statut      = $ecue['statut'];
                    $moyenneEcue = $ecue['moyenne'];   // null si en_attente

                    $ecuesApplaties[] = [
                        'ecue_id'        => $ecue['ecue_id'],
                        'ecue_nom'       => $ecue['ecue_nom'],
                        'ecue_code'      => $ecue['ecue_code'] ?? '',
                        // null = "En attente" côté Flutter, pas 0
                        'moyenne_cc'     => $ecue['moyenne_cc'],
                        'moyenne_examen' => $ecue['note_examen'],
                        'moyenne_finale' => $moyenneEcue,
                        'valide'         => $statut === 'valide',
                        'exclu_session1' => $ecue['absent_examen'] ?? false,
                        'credits'        => $ecue['credits'],
                        // Champ extra pour Flutter — afficher le bon libellé
                        'statut'         => $statut,
                        'raison'         => $ecue['raison'] ?? null,
                    ];

                    $creditsTotal += $ecue['credits'];
                    if ($statut === 'valide') {
                        $creditsValides += $ecue['credits'];
                    }
                }
            }

            $admis           = $resultat['statut'] === 'valide';
            $moyenneGenerale = $resultat['moyenne'];  // null si rien évalué

            return response()->json([
                'success' => true,
                'data'    => [
                    'moyenne_generale' => $moyenneGenerale,  // null → "N/A" côté Flutter
                    'credits_valides'  => $creditsValides,
                    'credits_total'    => $creditsTotal,
                    'admis'            => $admis,
                    'statut'           => $resultat['statut'],
                    'ecues'            => $ecuesApplaties,
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul des moyennes : ' . $e->getMessage(),
            ], 500);
        }
    }
}