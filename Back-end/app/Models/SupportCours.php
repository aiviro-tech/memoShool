<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportCours extends Model
{
    protected $table = 'supports_cours';

    protected $fillable = [
        'ecole_id',
        'cours_id',
        'enseignant_id',
        'titre',
        'description',
        'fichier_path',
        'fichier_nom',
        'fichier_type',
        'fichier_taille',
        'statut',
        'motif_rejet',
        'valide_par',
        'valide_at',
    ];

    protected $casts = [
        'valide_at' => 'datetime',
    ];

    public function cours()
    {
        return $this->belongsTo(Cours::class);
    }

    public function enseignant()
    {
        return $this->belongsTo(User::class, 'enseignant_id');
    }

    public function validateur()
    {
        return $this->belongsTo(User::class, 'valide_par');
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Helpers
    public function estEnAttente(): bool
    {
        return $this->statut === 'en_attente';
    }

    public function estValide(): bool
    {
        return $this->statut === 'valide';
    }
}
