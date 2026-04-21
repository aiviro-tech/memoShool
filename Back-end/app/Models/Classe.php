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
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];

    // Une classe appartient à une filière
    public function filiere()
    {
        return $this->belongsTo(Filiere::class);
    }

    // Une classe a plusieurs étudiants
    public function etudiants()
    {
        return $this->belongsToMany(User::class, 'etudiant_classe', 'classe_id', 'user_id')
                    ->withPivot('annee_academique')
                    ->withTimestamps();
    }

    // Une classe a plusieurs cours
    public function cours()
    {
        return $this->hasMany(Cours::class);
    }

    // Une classe appartient à une école
        public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}