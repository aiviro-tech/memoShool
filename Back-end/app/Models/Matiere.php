<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Matiere extends Model
{
    protected $fillable = [
        'ecole_id',
        'nom',
        'code',
        'credits',
        'volume_horaire',
        'type',
        'niveau',
        'filiere_id',
        'description',
        'actif',
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];

    // Une matière appartient à une filière (nullable = tronc commun)
    public function filiere()
    {
        return $this->belongsTo(Filiere::class);
    }

    // Une matière a plusieurs cours
    public function cours()
    {
        return $this->hasMany(Cours::class);
    }

    // Une matière appartient à une école (via la filière)
        public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}