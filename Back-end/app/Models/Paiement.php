<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Paiement extends Model
{
    protected $table = 'paiements';

    protected $fillable = [
        'inscription_id',
        'etudiant_id',
        'montant',
        'currency',
        'mode_paiement',
        'fedapay_transaction_id',
        'fedapay_token',
        'reference_paiement',
        'numero_recu',
        'statut',
        'recu',
        'date_paiement',
    ];

    protected $casts = [
        'montant'       => 'decimal:2',
        'date_paiement' => 'datetime',
    ];

    public function inscription()
    {
        return $this->belongsTo(Inscription::class);
    }

    public function etudiant()
    {
        return $this->belongsTo(User::class, 'etudiant_id');
    }

    // Helpers
    public function estApprouve(): bool
    {
        return $this->statut === 'approved';
    }

    public function estEnAttente(): bool
    {
        return $this->statut === 'pending';
    }
}