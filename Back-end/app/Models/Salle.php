<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Salle extends Model
{
    protected $fillable = [
        'ecole_id',
        'nom',
        'code',
        'type',
        'capacite',
        'batiment',
        'disponible',
    ];

    protected $casts = [
        'disponible' => 'boolean',
    ];

    // Une salle a plusieurs cours
    public function cours()
    {
        return $this->hasMany(Cours::class);
    }

    // Une salle appartient à une école
        public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}