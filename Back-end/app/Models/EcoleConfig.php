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
        'montant'                      => 'decimal:2',
        // Entiers
        'poids_cc'                       => 'integer',
        'poids_examen'                   => 'integer',
        'credits_par_semestre'           => 'integer',
        'seuil_enjambement_pourcent'     => 'integer',
        'nombre_sessions'                => 'integer',
        'absences_max_par_ecue'          => 'integer',
        'absences_max_par_semestre'      => 'integer',
        'heures_absence_exclusion_s1_s2' => 'integer',
    ];

    // ── Relation ──────────────────────────────────────────────────────────────
    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // ── Accesseurs utilitaires ────────────────────────────────────────────────

    /**
     * Calcule la note finale d'un étudiant pour une ECUE.
     * note_finale = (note_cc * poids_cc/100) + (note_examen * poids_examen/100)
     */
    public function calculerNoteFinale(float $noteCC, float $noteExamen): float
    {
        return round(
            ($noteCC * $this->poids_cc / 100) + ($noteExamen * $this->poids_examen / 100),
            2
        );
    }

    /**
     * Détermine si un étudiant est admis à l'UE.
     * Conditions :
     *  1. note_examen >= note_minimale_examen
     *  2. note_finale >= moyenne_validation_ue
     */
    public function estAdmisUE(float $noteCC, float $noteExamen): bool
    {
        if ($noteExamen < (float) $this->note_minimale_examen) {
            return false;
        }
        return $this->calculerNoteFinale($noteCC, $noteExamen) >= (float) $this->moyenne_validation_ue;
    }

    /**
     * Retourne les valeurs par défaut sous forme de tableau.
     * Utile quand aucune config n'a encore été enregistrée.
     */
    public static function defauts(): array
    {
        return [
            'poids_cc'                       => 40,
            'poids_examen'                   => 60,
            'note_minimale_examen'           => 5.00,
            'moyenne_validation_ue'          => 10.00,
            'rattrapage_note_100_pourcent'   => true,
            'credits_par_semestre'           => 30,
            'seuil_enjambement_pourcent'     => 80,
            'nombre_sessions'                => 2,
            'absences_max_par_ecue'          => 3,
            'absences_max_par_semestre'      => 10,
            'heures_absence_exclusion_s1_s2' => 150,
        ];
    }
}