<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EcheanceClasse extends Model
{
    protected $table = 'echeances_classe';

    protected $fillable = [
        'classe_id',
        'numero',
        'montant',
        'date_limite',
        'libelle',
    ];

    protected $casts = [
        'date_limite' => 'date',
        'montant'     => 'decimal:2',
    ];

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function typesFrais()
    {
        return $this->belongsToMany(TypeFrais::class, 'echeance_types_frais', 'echeance_id', 'type_frais_id');
    }
}