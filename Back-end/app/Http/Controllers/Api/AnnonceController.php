<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Annonce;
use App\Models\FcmToken;
use App\Models\Classe;
use App\Models\MembreEcole;
use App\Services\FCMService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AnnonceController extends Controller
{
    /**
     * Lister les annonces visibles pour l'utilisateur connecté.
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user  = $request->user();
        $query = Annonce::with(['publiePar', 'classeCible'])
                        ->where('ecole_id', $ecole_id)
                        ->where('publie', true)
                        ->orderByDesc('date_publication');

        if ($user->isEtudiant()) {
            // Récupérer les classes de l'étudiant
            $classeIds  = $user->classes()->pluck('classes.id');
            $niveaux    = $user->classes()->pluck('classes.niveau');

            $query->where(function ($q) use ($classeIds, $niveaux) {
                $q->where('cible', 'tous')
                  ->orWhere(function ($q2) use ($classeIds, $niveaux) {
                      $q2->where('cible', 'etudiants')
                         ->where(function ($q3) use ($classeIds, $niveaux) {
                             $q3->whereNull('classe_cible')
                                ->whereNull('niveau_cible')
                                ->orWhereIn('classe_cible', $classeIds)
                                ->orWhereIn('niveau_cible', $niveaux);
                         });
                  });
            });

        } elseif ($user->isEnseignant()) {
            $query->where(function ($q) {
                $q->where('cible', 'tous')
                  ->orWhere('cible', 'enseignants');
            });
        }

        $annonces = $query->get();

        return response()->json([
            'success' => true,
            'data'    => $annonces,
            'total'   => $annonces->count(),
        ]);
    }

    /**
     * Créer une annonce (Admin uniquement).
     */
    public function store(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent publier des annonces.',
            ], 403);
        }

        $validated = $request->validate([
            'titre'        => 'required|string|max:255',
            'contenu'      => 'required|string',
            'cible'        => 'required|in:tous,etudiants,enseignants',
            'niveau_cible' => 'nullable|in:L1,L2,L3,M1,M2|required_if:cible,etudiants',
            'classe_cible' => 'nullable|exists:classes,id',
            'publie'       => 'sometimes|boolean',
        ]);

        // Si classe_cible est défini, niveau_cible n'est pas nécessaire
        if (isset($validated['classe_cible'])) {
            $validated['niveau_cible'] = null;
        }

        $annonce = Annonce::create([
            ...$validated,
            'ecole_id'         => $ecole_id,
            'publie_par'       => $user->id,
            'date_publication' => isset($validated['publie']) && $validated['publie']
                                  ? now()
                                  : null,
        ]);

        // Envoyer notification push si publiée immédiatement
        if ($annonce->publie) {
            $this->envoyerNotificationAnnonce($annonce, $ecole_id);
        }

        return response()->json([
            'success' => true,
            'message' => 'Annonce créée avec succès.',
            'data'    => $annonce->load(['publiePar', 'classeCible']),
        ], 201);
    }

    /**
     * Modifier une annonce.
     */
    public function update(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user    = $request->user();
        $annonce = Annonce::where('ecole_id', $ecole_id)->findOrFail($id);

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        $validated = $request->validate([
            'titre'        => 'sometimes|string|max:255',
            'contenu'      => 'sometimes|string',
            'cible'        => 'sometimes|in:tous,etudiants,enseignants',
            'niveau_cible' => 'nullable|in:L1,L2,L3,M1,M2',
            'classe_cible' => 'nullable|exists:classes,id',
            'publie'       => 'sometimes|boolean',
        ]);

        // Si on publie maintenant
        if (isset($validated['publie']) && $validated['publie'] && !$annonce->publie) {
            $validated['date_publication'] = now();
        }

        $annonce->update($validated);

        // Envoyer notification si vient d'être publiée
        if (isset($validated['publie']) && $validated['publie']) {
            $this->envoyerNotificationAnnonce($annonce, $ecole_id);
        }

        return response()->json([
            'success' => true,
            'message' => 'Annonce mise à jour.',
            'data'    => $annonce->fresh(['publiePar', 'classeCible']),
        ]);
    }

    /**
     * Supprimer une annonce.
     */
    public function destroy(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user    = $request->user();
        $annonce = Annonce::where('ecole_id', $ecole_id)->findOrFail($id);

        if (!$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        $annonce->delete();

        return response()->json([
            'success' => true,
            'message' => 'Annonce supprimée.',
        ]);
    }

    /**
     * Enregistrer ou mettre à jour le token FCM d'un utilisateur.
     */
    public function enregistrerToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token'  => 'required|string',
            'device' => 'nullable|in:android,ios',
        ]);

        FcmToken::updateOrCreate(
            ['token' => $validated['token']],
            [
                'user_id' => $request->user()->id,
                'device'  => $validated['device'] ?? 'android',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Token FCM enregistré.',
        ]);
    }

    /**
     * Envoyer une notification push pour une annonce.
     */
    private function envoyerNotificationAnnonce(Annonce $annonce, int $ecole_id): void
    {
        $userIds = $this->getDestinataires($annonce, $ecole_id);

        if (empty($userIds)) return;

        $notificationService = new \App\Services\NotificationService();
        $notificationService->notifierAnnonce(
            $annonce->id,
            $ecole_id,
            $userIds,
            $annonce->titre
        );
    }

    /**
     * Récupérer les IDs des destinataires selon la cible.
     */
    private function getDestinataires(Annonce $annonce, int $ecole_id): array
    {
        $query = MembreEcole::where('ecole_id', $ecole_id)
                            ->where('statut', 'actif');

        if ($annonce->cible === 'etudiants') {
            $query->where('role', 'etudiant');

            // Filtrer par classe si définie
            if ($annonce->classe_cible) {
                $etudiantIds = \App\Models\Classe::find($annonce->classe_cible)
                    ->etudiants()
                    ->pluck('users.id');
                return $etudiantIds->toArray();
            }

            // Filtrer par niveau si défini
            if ($annonce->niveau_cible) {
                $classeIds = Classe::where('ecole_id', $ecole_id)
                    ->where('niveau', $annonce->niveau_cible)
                    ->pluck('id');

                $etudiantIds = \DB::table('etudiant_classe')
                    ->whereIn('classe_id', $classeIds)
                    ->pluck('user_id');

                return $etudiantIds->toArray();
            }

        } elseif ($annonce->cible === 'enseignants') {
            $query->where('role', 'enseignant');
        }

        return $query->pluck('user_id')->toArray();
    }
}