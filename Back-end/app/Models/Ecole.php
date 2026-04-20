<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ecole extends Model {
    protected $table = 'ecoles';

    protected $fillable = [
        'nom_officiel', 'sigle', 'site_web', 'adresse', 'ville',
        'code_postal', 'pays', 'email_principal', 'email_secondaire',
        'tel_fixe', 'tel_mobile', 'nom_responsable', 'titre_responsable',
        'numero_rne', 'type_etablissement', 'description_courte',
        'description_complete', 'max_etudiants', 'max_enseignants',
        'statut', 'admin_id', 'motif_refus',
    ];

    public function admin() {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function membres() {
        return $this->hasMany(MembreEcole::class);
    }

    public function codes() {
        return $this->hasMany(CodeInvitation::class);
    }
}