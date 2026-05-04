<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $table = 'notifications';

    protected $fillable = [
        'user_id',
        'ecole_id',
        'titre',
        'contenu',
        'type',
        'data',
        'lu',
        'lu_at',
    ];

    protected $casts = [
        'lu'     => 'boolean',
        'lu_at'  => 'datetime',
        'data'   => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function ecole()
    {
        return $this->belongsTo(Ecole::class);
    }

    // Helpers
    public function marquerCommeLu(): void
    {
        $this->update([
            'lu'    => true,
            'lu_at' => now(),
        ]);
    }
}