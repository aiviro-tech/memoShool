<?php

namespace App\Services;

use App\Models\Paiement;
use FedaPay\FedaPay;
use FedaPay\Transaction;

class FedaPayService
{
    public function __construct()
    {
        FedaPay::setApiKey(config('services.fedapay.secret_key'));
        FedaPay::setEnvironment(config('services.fedapay.environment'));
    }

    /**
     * Initier une transaction FedaPay.
     */
    public function initierTransaction(
        Paiement $paiement,
        string $telephone,
        string $nom,
        string $prenom,
        string $email
    ): array {
        $transaction = Transaction::create([
            'description'  => "Paiement scolarité — {$nom} {$prenom}",
            'amount'       => (int) $paiement->montant,
            'currency'     => ['iso' => 'XOF'],
            'callback_url' => config('app.url') . '/api/paiements/webhook',
            'customer'     => [
                'firstname'    => $prenom,
                'lastname'     => $nom,
                'email'        => $email,
                'phone_number' => [
                    'number'  => $telephone,
                    'country' => 'BJ',
                ],
            ],
        ]);

        $token = $transaction->generateToken();

        $paiement->update([
            'fedapay_transaction_id' => $transaction->id,
            'fedapay_token'          => $token->token,
        ]);

        return [
            'transaction_id' => $transaction->id,
            'token'          => $token->token,
            'payment_url'    => $token->url,
        ];
    }

    /**
     * Vérifier le statut d'une transaction FedaPay.
     */
    public function verifierTransaction(string $transaction_id): array
    {
        $transaction = Transaction::retrieve($transaction_id);

        return [
            'id'     => $transaction->id,
            'statut' => $transaction->status,
            'amount' => $transaction->amount,
        ];
    }

    /**
     * Traiter le webhook FedaPay.
     *
     * CORRECTION : ajout des notifications automatiques
     * - Paiement approuvé → notification à l'étudiant
     * - Paiement échoué   → notification à l'étudiant
     */
    public function traiterWebhook(array $payload): void
    {
        $transactionId = $payload['entity']['id']     ?? null;
        $statut        = $payload['entity']['status'] ?? null;

        if (!$transactionId || !$statut) return;

        $paiement = Paiement::where('fedapay_transaction_id', $transactionId)
                            ->with('inscription.classe.filiere.ecole')
                            ->first();

        if (!$paiement) return;

        $ancienStatut = $paiement->statut;

        $paiement->update([
            'statut'        => $statut,
            'date_paiement' => $statut === 'approved' ? now() : null,
        ]);

        // Envoyer une notification uniquement si le statut vient de changer
        if ($ancienStatut === $statut) return;

        $notificationService = new NotificationService();
        $ecoleId = $paiement->inscription?->classe?->filiere?->ecole?->id;

        if (!$ecoleId) return;

        if ($statut === 'approved') {
            // Paiement approuvé → notifier l'étudiant
            $notificationService->notifierPaiementApprouve(
                $paiement->etudiant_id,
                $ecoleId,
                (float) $paiement->montant,
                $paiement->numero_recu ?? ''
            );
        } elseif (in_array($statut, ['canceled', 'declined', 'failed'])) {
            // Paiement échoué → notifier l'étudiant
            $notificationService->notifierPaiementEchoue(
                $paiement->etudiant_id,
                $ecoleId,
                (float) $paiement->montant
            );
        }
    }
}