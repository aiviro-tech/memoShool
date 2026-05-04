<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ecue extends Model
{
    protected $fillable = [
        'ecole_id',
        'ue_id',
        'nom',
        'code',
        'credits',
        'volume_horaire',
        'type',
        'niveau',
        'description',
        'actif',
    ];

    protected $casts = [
        'actif' => 'boolean',
    ];


    // Un ECUE a plusieurs cours
    public function cours()
    {
        return $this->hasMany(Cours::class);
    }

    // Un ECUE appartient à une école (via ue → semestre → filiere)
    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Relation avec l'UE
    public function ue()
    {
        return $this->belongsTo(Ue::class);
    }
}