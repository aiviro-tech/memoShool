<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Classe extends Model
{
    protected $fillable = [
        'ecole_id',
        'nom',
        'code',
        'niveau',
        'filiere_id',
        'annee_academique',
        'actif',
        'coutScolarite',
    ];

    protected $casts = [
        'actif'          => 'boolean',
        'coutScolarite'  => 'decimal:2',
    ];

    // ── Relations ────────────────────────────────────────────────────────────

    /** La filière à laquelle appartient cette classe */
    public function filiere()
    {
        return $this->belongsTo(Filiere::class);
    }

    /** L'école à laquelle appartient cette classe */
    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    /** Les étudiants inscrits (via table pivot inscriptions) */
    public function etudiants()
    {
        return $this->belongsToMany(
            User::class,
            'inscriptions',
            'classe_id',
            'etudiant_id'
        )
        ->wherePivot('statut', 'validee')
        ->withPivot('annee_academique', 'statut')
        ->withTimestamps();
    }

    /** Toutes les inscriptions de cette classe */
    public function inscriptions()
    {
        return $this->hasMany(Inscription::class);
    }

    /** Les cours de cette classe */
    public function cours()
    {
        return $this->hasMany(Cours::class);
    }

    /** Les types de frais configurés pour cette classe */
    public function typesFrais()
    {
        return $this->hasMany(TypeFrais::class)->orderBy('obligatoire', 'desc');
    }

    /** Les échéances de paiement de cette classe */
    public function echeances()
    {
        return $this->hasMany(EcheanceClasse::class)->orderBy('numero');
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Indique si des frais sont configurés pour cette classe.
     */
    public function aDesFraisConfigures(): bool
    {
        return $this->typesFrais()->exists();
    }

    /**
     * Retourne le montant total des frais obligatoires.
     * Utilise coutScolarite comme fallback si aucun TypeFrais n'est défini.
     */
    public function getMontantTotalFrais(): float
    {
        if ($this->aDesFraisConfigures()) {
            return (float) $this->typesFrais()
                ->where('obligatoire', true)
                ->sum('montant');
        }

        return (float) ($this->coutScolarite ?? 0);
    }
}