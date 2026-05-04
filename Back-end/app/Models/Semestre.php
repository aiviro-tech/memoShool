<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Semestre extends Model
{
    use HasFactory;

    protected $fillable = [
        'filiere_id',
        'numero',
        'annee_academique',
        'date_debut',
        'date_fin',
        'description',
    ];

    public function filiere()
    {
        return $this->belongsTo(Filiere::class);
    }

    public function ues()
    {
        return $this->hasMany(Ue::class);
    }
}