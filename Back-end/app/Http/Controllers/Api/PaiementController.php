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

        $inscription = Inscription::with(['classe.filiere', 'classe.typesFrais'])
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

        // Échéances de la classe
        $echeances = EcheanceClasse::where('classe_id', $inscription->classe_id)
            ->orderBy('numero')
            ->get();

        // Montant total obligatoire
        $montantTotal = $inscription->classe->typesFrais
            ->where('obligatoire', true)
            ->sum('montant');

        // Montant déjà payé
        $montantPaye = Paiement::where('inscription_id', $inscription->id)
            ->where('statut', 'approved')
            ->sum('montant');

        $soldeRestant = $montantTotal - $montantPaye;

        return response()->json([
            'success' => true,
            'data'    => [
                'inscription'   => $inscription,
                'types_frais'   => $inscription->classe->typesFrais,
                'echeances'     => $echeances,
                'montant_total' => $montantTotal,
                'montant_paye'  => $montantPaye,
                'solde_restant' => $soldeRestant,
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

        // Vérifier que le montant ne dépasse pas le solde restant
        $montantTotal = $inscription->classe->typesFrais
            ->where('obligatoire', true)
            ->sum('montant');

        $montantPaye = Paiement::where('inscription_id', $inscription->id)
            ->where('statut', 'approved')
            ->sum('montant');

        $soldeRestant = $montantTotal - $montantPaye;

        if ($validated['montant'] > $soldeRestant) {
            return response()->json([
                'success' => false,
                'message' => "Le montant saisi ({$validated['montant']} FCFA) dépasse le solde restant ({$soldeRestant} FCFA).",
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
     * Webhook FedaPay.
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
     * Gérer les types de frais (Admin).
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
}