<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TypeFrais extends Model
{
    protected $table = 'types_frais';

    protected $fillable = [
        'classe_id',
        'libelle',
        'montant',
        'obligatoire',
    ];

    protected $casts = [
        'montant'     => 'decimal:2',
        'obligatoire' => 'boolean',
    ];

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function echeances()
    {
        return $this->belongsToMany(EcheanceClasse::class, 'echeance_types_frais', 'type_frais_id', 'echeance_id');
    }
}