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

    public function ecue()
    {
        return $this->belongsTo(Ecue::class);
    }

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function enseignant()
    {
        return $this->belongsTo(User::class, 'enseignant_id');
    }

    public function notes()
    {
        return $this->hasMany(Note::class);
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Helpers
    public function estExamen(): bool
    {
        return $this->type === 'EXAMEN';
    }

    public function estRattrapage(): bool
    {
        return $this->session === 2 && $this->type === 'EXAMEN';
    }

    public function estCC(): bool
    {
        return in_array($this->type, ['CC', 'TP', 'TD']);
    }
}