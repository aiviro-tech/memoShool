<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EcheanceClasse;
use App\Models\Inscription;
use App\Models\Paiement;
use App\Models\TypeFrais;
use App\Services\FedaPayService;
use App\Services\RecuPaiementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaiementController extends Controller
{
    /**
     * Consulter les frais et le solde d'un étudiant.
     *
     * CORRECTION : On distingue maintenant le cas "frais non configurés"
     * du cas "solde = 0". Le champ `frais_configures` est retourné
     * pour que le frontend puisse afficher le bon message.
     */
    public function fraisEtudiant(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $etudiant_id = $user->isEtudiant()
            ? $user->id
            : $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'etudiant_id est requis.',
            ], 422);
        }

        // Charger l'inscription avec classe + filière + typesFrais + écheances
        $inscription = Inscription::with([
                'classe.filiere',
                'classe.typesFrais',
                'classe.echeances',
            ])
            ->where('etudiant_id', $etudiant_id)
            ->where('statut', 'validee')
            ->whereHas('classe.filiere', fn($q) => $q->where('ecole_id', $ecole_id))
            ->latest()
            ->first();

        if (!$inscription) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune inscription active trouvée.',
            ], 404);
        }

        $typesFrais      = $inscription->classe->typesFrais;
        $echeances       = $inscription->classe->echeances;

        // ── CORRECTION PRINCIPALE ────────────────────────────────────────────
        // On considère les frais "configurés" si au moins un TypeFrais existe.
        $fraisConfigures = $typesFrais->isNotEmpty();

        // Montant total : somme des frais obligatoires.
        // Fallback sur coutScolarite si aucun TypeFrais n'est défini.
        if ($fraisConfigures) {
            $montantTotal = $typesFrais->where('obligatoire', true)->sum('montant');
        } else {
            $montantTotal = $inscription->classe->coutScolarite ?? 0;
        }

        // Montant déjà payé (paiements approuvés uniquement)
        $montantPaye = Paiement::where('inscription_id', $inscription->id)
            ->where('statut', 'approved')
            ->sum('montant');

        $soldeRestant = max(0, $montantTotal - $montantPaye);

        // Scolarité soldée : frais configurés ET tout payé
        $scolariteSoldee = $fraisConfigures
            && $montantTotal > 0
            && $soldeRestant <= 0;

        return response()->json([
            'success' => true,
            'data'    => [
                'inscription'      => $inscription,
                'types_frais'      => $typesFrais,
                'echeances'        => $echeances,
                'montant_total'    => (float) $montantTotal,
                'montant_paye'     => (float) $montantPaye,
                'solde_restant'    => (float) $soldeRestant,
                'frais_configures' => $fraisConfigures,   // ← NOUVEAU CHAMP
                'scolarite_soldee' => $scolariteSoldee,   // ← NOUVEAU CHAMP
            ],
        ]);
    }

    /**
     * Initier un paiement via FedaPay.
     */
    public function initierPaiement(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'inscription_id' => 'required|exists:inscriptions,id',
            'montant'        => 'required|numeric|min:1',
            'mode_paiement'  => 'required|in:mtn_money,moov_money',
            'telephone'      => 'required|string|max:20',
        ]);

        $inscription = Inscription::with(['etudiant', 'classe.typesFrais'])
            ->findOrFail($validated['inscription_id']);

        // Vérifier que l'étudiant est bien le propriétaire
        if ($user->isEtudiant() && $inscription->etudiant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez payer que votre propre inscription.',
            ], 403);
        }

        // Calcul du solde restant
        $typesFrais      = $inscription->classe->typesFrais;
        $fraisConfigures = $typesFrais->isNotEmpty();

        $montantTotal = $fraisConfigures
            ? $typesFrais->where('obligatoire', true)->sum('montant')
            : ($inscription->classe->coutScolarite ?? 0);

        $montantPaye = Paiement::where('inscription_id', $inscription->id)
            ->where('statut', 'approved')
            ->sum('montant');

        $soldeRestant = max(0, $montantTotal - $montantPaye);

        // Si les frais sont configurés, on ne peut pas dépasser le solde restant
        if ($fraisConfigures && $soldeRestant > 0 && $validated['montant'] > $soldeRestant) {
            return response()->json([
                'success' => false,
                'message' => "Le montant saisi ({$validated['montant']} FCFA) dépasse le solde restant ({$soldeRestant} FCFA).",
            ], 422);
        }

        // Si frais configurés et déjà tout payé
        if ($fraisConfigures && $soldeRestant <= 0 && $montantTotal > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Votre scolarité est déjà entièrement réglée.',
            ], 422);
        }

        // Créer le paiement en pending
        $paiement = Paiement::create([
            'inscription_id' => $validated['inscription_id'],
            'etudiant_id'    => $inscription->etudiant_id,
            'montant'        => $validated['montant'],
            'currency'       => 'XOF',
            'mode_paiement'  => $validated['mode_paiement'],
            'statut'         => 'pending',
        ]);

        // Initier la transaction FedaPay
        try {
            $service  = new FedaPayService();
            $resultat = $service->initierTransaction(
                $paiement,
                $validated['telephone'],
                $inscription->etudiant->last_name,
                $inscription->etudiant->first_name,
                $inscription->etudiant->email
            );

            return response()->json([
                'success' => true,
                'message' => 'Transaction initiée avec succès.',
                'data'    => [
                    'paiement'    => $paiement->fresh(),
                    'payment_url' => $resultat['payment_url'],
                    'token'       => $resultat['token'],
                ],
            ]);

        } catch (\Exception $e) {
            $paiement->update(['statut' => 'canceled']);

            return response()->json([
                'success' => false,
                'message' => 'Erreur FedaPay : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Webhook FedaPay (sans authentification).
     */
    public function webhook(Request $request): JsonResponse
    {
        try {
            $service = new FedaPayService();
            $service->traiterWebhook($request->all());

            return response()->json(['success' => true]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Historique des paiements d'un étudiant.
     */
    public function historique(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $etudiant_id = $user->isEtudiant()
            ? $user->id
            : $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'etudiant_id est requis.',
            ], 422);
        }

        $paiements = Paiement::with(['inscription.classe'])
            ->where('etudiant_id', $etudiant_id)
            ->whereHas('inscription.classe.filiere', fn($q) => $q->where('ecole_id', $ecole_id))
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $paiements,
        ]);
    }

    /**
     * Vérifier manuellement le statut d'un paiement.
     */
    public function verifierStatut(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $paiement = Paiement::findOrFail($id);

        if (!$paiement->fedapay_transaction_id) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune transaction FedaPay associée.',
            ], 422);
        }

        try {
            $service  = new FedaPayService();
            $resultat = $service->verifierTransaction($paiement->fedapay_transaction_id);

            if ($paiement->statut !== $resultat['statut']) {
                $paiement->update([
                    'statut'        => $resultat['statut'],
                    'date_paiement' => $resultat['statut'] === 'approved' ? now() : null,
                ]);
            }

            return response()->json([
                'success' => true,
                'data'    => $paiement->fresh(),
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur FedaPay : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Générer le reçu d'un paiement.
     */
    public function genererRecu(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $paiement = Paiement::findOrFail($id);

        if (!$paiement->estApprouve()) {
            return response()->json([
                'success' => false,
                'message' => 'Le reçu ne peut être généré que pour un paiement approuvé.',
            ], 422);
        }

        try {
            $service  = new RecuPaiementService();
            $resultat = $service->generer($paiement->id);

            return response()->json([
                'success' => true,
                'message' => 'Reçu généré avec succès.',
                'data'    => $resultat['paiement'],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur génération reçu : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Télécharger le reçu d'un paiement.
     */
    public function telechargerRecu(Request $request, int $ecole_id, int $id)
    {
        $paiement = Paiement::findOrFail($id);

        if (!$paiement->recu || !\Storage::disk('public')->exists($paiement->recu)) {
            return response()->json([
                'success' => false,
                'message' => 'Reçu non disponible. Veuillez le générer d\'abord.',
            ], 404);
        }

        return \Storage::disk('public')->download(
            $paiement->recu,
            "recu_{$paiement->numero_recu}.pdf"
        );
    }

    /**
     * Créer un type de frais directement depuis le PaiementController.
     * (Kept for backward-compat — préférer TypeFraisController::store)
     */
    public function storeFrais(Request $request, int $ecole_id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les administrateurs peuvent gérer les frais.',
            ], 403);
        }

        $validated = $request->validate([
            'classe_id'   => 'required|exists:classes,id',
            'libelle'     => 'required|string|max:255',
            'montant'     => 'required|numeric|min:0',
            'obligatoire' => 'sometimes|boolean',
        ]);

        $frais = TypeFrais::create($validated);

        // Synchroniser coutScolarite
        $total = TypeFrais::where('classe_id', $validated['classe_id'])
            ->where('obligatoire', true)
            ->sum('montant');
        \App\Models\Classe::where('id', $validated['classe_id'])
            ->update(['coutScolarite' => $total]);

        return response()->json([
            'success' => true,
            'message' => 'Type de frais créé avec succès.',
            'data'    => $frais,
        ], 201);
    }

    /**
     * Générer la fiche de frais d'un étudiant.
     */
    public function ficheFrais(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'inscription_id' => 'required|exists:inscriptions,id',
        ]);

        $inscription = Inscription::findOrFail($validated['inscription_id']);

        if ($user->isEtudiant() && $inscription->etudiant_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé.',
            ], 403);
        }

        try {
            $service  = new \App\Services\FicheFraisService();
            $resultat = $service->generer($inscription->id);

            return \Storage::disk('public')->download(
                $resultat['path'],
                "fiche_frais_{$inscription->annee_academique}.pdf"
            );

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur : ' . $e->getMessage(),
            ], 500);
        }
    }

    // ── Admin : liste des paiements de tous les étudiants ────────────────────

    /**
     * Liste tous les paiements d'une école (Admin).
     */
    public function indexAdmin(Request $request, int $ecole_id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        $query = Paiement::with(['etudiant', 'inscription.classe'])
            ->whereHas('inscription.classe.filiere', fn($q) => $q->where('ecole_id', $ecole_id));

        if ($request->filled('statut')) {
            $query->where('statut', $request->statut);
        }
        if ($request->filled('classe_id')) {
            $query->whereHas('inscription', fn($q) => $q->where('classe_id', $request->classe_id));
        }

        $paiements = $query->orderByDesc('created_at')->get();

        return response()->json(['success' => true, 'data' => $paiements]);
    }

    /**
     * Solde d'un étudiant spécifique (Admin).
     */
    public function soldeEtudiantAdmin(Request $request, int $ecole_id, int $etudiant_id): JsonResponse
    {
        if (!$request->user()->isAdmin()) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        // Réutiliser la logique de fraisEtudiant en simulant la requête
        $request->merge(['etudiant_id' => $etudiant_id]);
        return $this->fraisEtudiant($request, $ecole_id);
    }
}