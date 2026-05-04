<?php

namespace App\Services;

use App\Models\Paiement;
use App\Models\Inscription;
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
            'description' => "Paiement scolarité — {$nom} {$prenom}",
            'amount'      => (int) $paiement->montant,
            'currency'    => ['iso' => 'XOF'],
            'callback_url' => config('app.url') . '/api/paiements/webhook',
            'customer'    => [
                'firstname' => $prenom,
                'lastname'  => $nom,
                'email'     => $email,
                'phone_number' => [
                    'number'   => $telephone,
                    'country'  => 'BJ',
                ],
            ],
        ]);

        // Générer le token de paiement
        $token = $transaction->generateToken();

        // Mettre à jour le paiement avec les infos FedaPay
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
     */
    public function traiterWebhook(array $payload): void
    {
        $transactionId = $payload['entity']['id'] ?? null;
        $statut        = $payload['entity']['status'] ?? null;

        if (!$transactionId || !$statut) return;

        $paiement = Paiement::where('fedapay_transaction_id', $transactionId)->first();

        if (!$paiement) return;

        $paiement->update([
            'statut'        => $statut,
            'date_paiement' => $statut === 'approved' ? now() : null,
        ]);
    }
}