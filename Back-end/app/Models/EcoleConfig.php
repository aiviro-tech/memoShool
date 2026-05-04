<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EcoleConfig extends Model
{
    protected $table = 'ecole_configs';

    protected $fillable = [
        'ecole_id',
        'poids_cc',
        'poids_examen',
        'note_minimale_examen',
        'moyenne_validation_ue',
        'rattrapage_note_100_pourcent',
        'credits_par_semestre',
        'seuil_enjambement_pourcent',
        'nombre_sessions',
        'absences_max_par_ecue',
        'absences_max_par_semestre',
        'heures_absence_exclusion_s1_s2',
    ];

    protected $casts = [
        'rattrapage_note_100_pourcent' => 'boolean',
        'note_minimale_examen'         => 'decimal:2',
        'moyenne_validation_ue'        => 'decimal:2',
    ];

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}