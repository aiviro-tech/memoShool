<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AutorisationSaisieNote extends Model
{
    protected $table = 'autorisations_saisie_notes';

    protected $fillable = [
        'ecole_id',
        'enseignant_id',
        'autorise_par',
        'semestre_id',
        'actif',
        'date_autorisation',
        'date_expiration',
        'observation',
    ];

    protected $casts = [
        'actif'             => 'boolean',
        'date_autorisation' => 'datetime',
        'date_expiration'   => 'datetime',
    ];

    public function enseignant()
    {
        return $this->belongsTo(User::class, 'enseignant_id');
    }

    public function autorisePar()
    {
        return $this->belongsTo(User::class, 'autorise_par');
    }

    public function semestre()
    {
        return $this->belongsTo(Semestre::class);
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Helpers
    public function estActive(): bool
    {
        if (!$this->actif) return false;
        if ($this->date_expiration && $this->date_expiration->isPast()) return false;
        return true;
    }
}