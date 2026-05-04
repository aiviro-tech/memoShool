<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ue extends Model
{
    use HasFactory;

    protected $fillable = [
        'semestre_id',
        'code',
        'libelle',
        'credits_ects',
        'description',
    ];

    /**
     * Relation avec le Semestre
     */
    public function semestre()
    {
        return $this->belongsTo(Semestre::class);
    }

    /**
     * Relation avec les ECUEs (anciennes Matières)
     */
    public function ecues()
    {
        return $this->hasMany(Ecue::class);
    }
}