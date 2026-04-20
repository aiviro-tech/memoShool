<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CodeInvitation extends Model {
    protected $table = 'codes_invitation';

    protected $fillable = [
        'ecole_id', 'code', 'role', 'destinataire', 'utilise', 'genere_par'
    ];

    public function ecole() {
        return $this->belongsTo(Ecole::class);
    }
}