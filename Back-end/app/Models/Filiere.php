<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Filiere extends Model
{
    protected $fillable = [
        'ecole_id', 
        'nom',
        'code',
        'description',
        'actif',
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];

    // Une filière a plusieurs classes
    public function classes()
    {
        return $this->hasMany(Classe::class);
    }

    // Une filière a plusieurs matières
    public function matieres()
    {
        return $this->hasMany(Matiere::class);
    }

        // Une filière appartient à une école
        public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}