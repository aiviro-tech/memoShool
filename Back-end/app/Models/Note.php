<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Note extends Model
{
    protected $table = 'notes';

    protected $fillable = [
        'ecole_id',
        'devoir_id',
        'etudiant_id',
        'valeur',
        'observation',
        'absent',
    ];

    protected $casts = [
        'valeur'  => 'decimal:2',
        'absent'  => 'boolean',
    ];

    public function devoir()
    {
        return $this->belongsTo(Devoir::class);
    }

    public function etudiant()
    {
        return $this->belongsTo(User::class, 'etudiant_id');
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }
}