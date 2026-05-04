<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absence extends Model
{
    protected $table = 'absences';

    protected $fillable = [
        'ecole_id',
        'cours_id',
        'etudiant_id',
        'present',
        'justifiee',
        'type_justification',
        'date_justification',
        'justifie_par',
        'observation',
    ];

    protected $casts = [
        'present'            => 'boolean',
        'justifiee'          => 'boolean',
        'date_justification' => 'datetime',
    ];

    public function cours()
    {
        return $this->belongsTo(Cours::class);
    }

    public function etudiant()
    {
        return $this->belongsTo(User::class, 'etudiant_id');
    }

    public function justifiePar()
    {
        return $this->belongsTo(User::class, 'justifie_par');
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Helpers
    public function estAbsent(): bool
    {
        return !$this->present;
    }

    public function estNonJustifiee(): bool
    {
        return !$this->present && !$this->justifiee;
    }

    public function delaiJustificatifDepasse(): bool
    {
        if ($this->justifiee) return false;
        return $this->created_at->addHours(72)->isPast();
    }
}