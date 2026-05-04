<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;        
use Laravel\Sanctum\HasApiTokens;  // ← AJOUTE CETTE LIGNE

/**
 * Modèle User pour l'authentification et les données utilisateur.
 *
 * @property string $first_name
 * @property string $last_name
 */
class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, HasApiTokens, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
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
    ];

    /**
     * Retourne le nom complet (prénom + nom)
     *
     * @return string
     */
    public function getFullNameAttribute(): string
    {
        // On concatène prénom et nom avec un espace
        // Si l'un des deux est vide, on évite les doubles espaces
        return trim("{$this->first_name} {$this->last_name}");
    }

    /**
    * Les attributs qui seront automatiquement ajoutés quand le modèle est converti en tableau/JSON
     *
     * @var array
     */
    protected $appends = ['full_name'];

    
    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    public function emailOtps()
        {
            return $this->hasMany(EmailOtp::class);
        }

    
    public function passwordResetOtps()
    {
        return $this->hasMany(PasswordResetOtp::class);
    }

    public function fcmTokens()
    {
        return $this->hasMany(FcmToken::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    
    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // Les cours assignés à cet enseignant
    public function coursEnseignes()
    {
        return $this->hasMany(Cours::class, 'enseignant_id');
    }

    // Les classes auxquelles appartient cet étudiant
    public function classes()
    {
        return $this->belongsToMany(Classe::class, 'etudiant_classe', 'user_id', 'classe_id')
                    ->withPivot('annee_academique')
                    ->withTimestamps();
    }

    // Helpers pour vérifier le rôle
    public function isAdmin(): bool { return $this->role === 'admin'; }
    public function isEnseignant(): bool { return $this->role === 'enseignant'; }
    public function isEtudiant(): bool { return $this->role === 'etudiant'; }
}
