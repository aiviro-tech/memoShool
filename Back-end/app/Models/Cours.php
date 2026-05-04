<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cours extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'ecole_id',
        'ecue_id',
        'enseignant_id',
        'salle_id',
        'classe_id',
        'semestre_id',
        'date_cours',
        'heure_debut',
        'heure_fin',
        'statut',
        'motif_annulation',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'date_cours' => 'date',
    ];

    // Un cours appartient à un ECUE
    public function ecue()
    {
        return $this->belongsTo(Ecue::class);
    }

    // Un cours appartient à un enseignant
    public function enseignant()
    {
        return $this->belongsTo(User::class, 'enseignant_id');
    }

    // Un cours appartient à une salle
    public function salle()
    {
        return $this->belongsTo(Salle::class);
    }

    // Un cours appartient à une classe
    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    // Un cours appartient à un semestre
    public function semestre()
    {
        return $this->belongsTo(Semestre::class);
    }

    // Qui a créé ce cours
    public function createur()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Un cours appartient à une école
    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Supports de cours associés
    public function supports()
    {
        return $this->hasMany(SupportCours::class);
    }
}