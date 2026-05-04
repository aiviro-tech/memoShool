<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Annonce extends Model
{
    protected $table = 'annonces';

    protected $fillable = [
        'ecole_id',
        'publie_par',
        'titre',
        'contenu',
        'cible',
        'niveau_cible',
        'classe_cible',
        'date_publication',
        'publie',
    ];

    protected $casts = [
        'publie'           => 'boolean',
        'date_publication' => 'datetime',
    ];

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    public function publiePar()
    {
        return $this->belongsTo(User::class, 'publie_par');
    }

    public function classeCible()
    {
        return $this->belongsTo(Classe::class, 'classe_cible');
    }
}