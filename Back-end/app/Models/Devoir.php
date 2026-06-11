<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Devoir extends Model
{
    protected $table = 'devoirs';

    protected $fillable = [
        'ecole_id',
        'ecue_id',
        'classe_id',
        'enseignant_id',
        'titre',
        'type',
        'session',
        'bareme',
        'date_evaluation',
        'duree',
        'description',
    ];

    protected $casts = [
        'date_evaluation' => 'date',
        'bareme'          => 'decimal:2',
    ];

    // Relation avec ECUE
    public function ecue()
    {
        return $this->belongsTo(Ecue::class);
    }

    // Relation avec Classe
    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    // Relation avec Enseignant
    public function enseignant()
    {
        return $this->belongsTo(User::class, 'enseignant_id');
    }

    // Relation avec Notes
    public function notes()
    {
        return $this->hasMany(Note::class);
    }

    // Relation avec Ecole
    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
    
    // Helper pour obtenir le semestre via l'ECUE
    public function getSemestreIdAttribute()
    {
        if ($this->ecue && $this->ecue->ue) {
            return $this->ecue->ue->semestre_id;
        }
        return null;
    }

    // Helper pour vérifier si c'est un examen
    public function estExamen(): bool
    {
        return $this->type === 'EXAMEN';
    }

    // Helper pour vérifier si c'est un rattrapage
    public function estRattrapage(): bool
    {
        return $this->session === 2 && $this->type === 'EXAMEN';
    }

    // Helper pour vérifier si c'est un contrôle continu
    public function estCC(): bool
    {
        return in_array($this->type, ['CC', 'TP', 'TD']);
    }
}