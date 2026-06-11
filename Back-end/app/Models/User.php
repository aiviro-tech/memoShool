<?php

// ============================================================
// FICHIER : app/Models/User.php
// ACTION  : Remplace COMPLÈTEMENT ton fichier User.php existant
// ============================================================

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'password',
        'role',
        'date_of_birth',
        'gender',
        'nationality',
        'phone',
        'email_verified_at',
        'photo_profil',      // ← AJOUTÉ pour la photo de profil
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password'          => 'hashed',
    ];

    // ── Accesseur nom complet ────────────────────────────────────────────────
    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    // ── Rôles ────────────────────────────────────────────────────────────────
    public function isAdmin(): bool
    {
        return in_array($this->role, ['admin', 'super_admin']);
    }

    public function isEnseignant(): bool
    {
        return $this->role === 'enseignant';
    }

    public function isEtudiant(): bool
    {
        return $this->role === 'etudiant';
    }

    // ── Relations ────────────────────────────────────────────────────────────

    // Classes via inscriptions VALIDÉES
    public function classes()
    {
        return $this->belongsToMany(
            Classe::class,
            'inscriptions',
            'etudiant_id',
            'classe_id'
        )->wherePivot('statut', 'validee');
    }

    // Toutes les inscriptions
    public function inscriptions()
    {
        return $this->hasMany(Inscription::class, 'etudiant_id');
    }

    // Inscription active (validée)
    public function inscriptionActive()
    {
        return $this->hasOne(Inscription::class, 'etudiant_id')
                    ->where('statut', 'validee')
                    ->latest();
    }

    // OTPs email
    public function emailOtps()
    {
        return $this->hasMany(EmailOtp::class);
    }

    // OTPs reset password
    public function passwordResetOtps()
    {
        return $this->hasMany(PasswordResetOtp::class);
    }

    // Membre d'école
    public function membresEcole()
    {
        return $this->hasMany(MembreEcole::class);
    }

    // Notifications
    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    // Email vérifié
    public function hasVerifiedEmail(): bool
    {
        return $this->email_verified_at !== null;
    }
}