<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MembreEcole extends Model {
    protected $table = 'membres_ecole';

    protected $fillable = [
        'user_id', 'ecole_id', 'role', 'statut', 'code_utilise',
        'niveau', 'matricule', 'annee_entree', 'statut_etudiant',
        'tuteur_nom', 'tuteur_tel', 'matiere_principale', 'diplome',
        'experience_annees', 'type_contrat', 'poste', 'service',
        'niveau_acces', 'motif_rejet', 'validated_by', 'validated_at', 'joined_at',
    ];

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function ecole() {
        return $this->belongsTo(Ecole::class);
    }
}