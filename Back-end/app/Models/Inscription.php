<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Inscription extends Model
{
    protected $table = 'inscriptions';

    protected $fillable = [
        'annee_academique',
        'date_inscription',
        'statut',
        'motif_rejet',
        'etudiant_id',
        'classe_id',
    ];

    protected $casts = [
        'date_inscription' => 'date',
    ];

    public function etudiant()
    {
        return $this->belongsTo(User::class, 'etudiant_id');
    }

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function paiements()
    {
        return $this->hasMany(Paiement::class);
    }

    // Helpers
    public function estValidee(): bool
    {
        return $this->statut === 'validee';
    }

    public function totalPaye(): float
    {
        return $this->paiements()
            ->where('statut', 'approved')
            ->sum('montant');
    }

    public function soldeRestant(): float
    {
        $montantTotal = $this->classe
            ->typesFrais()
            ->where('obligatoire', true)
            ->sum('montant');
            
        return $montantTotal - $this->totalPaye();
    }
}