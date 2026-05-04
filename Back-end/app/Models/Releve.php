<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Releve extends Model
{
    protected $table = 'releves';

    protected $fillable = [
        'ecole_id',
        'etudiant_id',
        'semestre_id',
        'classe_id',
        'session',
        'moyenne_generale',
        'statut',
        'fichier_path',
        'date_generation',
    ];

    protected $casts = [
        'moyenne_generale' => 'decimal:2',
        'date_generation'  => 'datetime',
    ];

    public function etudiant()
    {
        return $this->belongsTo(User::class, 'etudiant_id');
    }

    public function semestre()
    {
        return $this->belongsTo(Semestre::class);
    }

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}