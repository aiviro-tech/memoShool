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
        'numero'      => 'integer',
    ];

    // ── Attributs calculés ────────────────────────────────────────────────────

    /**
     * Indique si la date limite est dépassée.
     */
    public function getEstEchueAttribute(): bool
    {
        return $this->date_limite->isPast();
    }

    /**
     * Nombre de jours restants avant la date limite (négatif si dépassée).
     */
    public function getJoursRestantsAttribute(): int
    {
        return (int) now()->startOfDay()->diffInDays($this->date_limite->startOfDay(), false);
    }

    /**
     * Statut lisible : 'en_cours', 'bientot', 'echue'
     * - echue    : date passée
     * - bientot  : dans les 7 prochains jours
     * - en_cours : plus de 7 jours restants
     */
    public function getStatutAttribute(): string
    {
        $jours = $this->jours_restants;
        if ($jours < 0)  return 'echue';
        if ($jours <= 7) return 'bientot';
        return 'en_cours';
    }

    // ── Relations ─────────────────────────────────────────────────────────────

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function typesFrais()
    {
        return $this->belongsToMany(
            TypeFrais::class,
            'echeance_types_frais',
            'echeance_id',
            'type_frais_id'
        );
    }

    // ── Scopes ────────────────────────────────────────────────────────────────

    /**
     * Scope : échéances non encore échues.
     */
    public function scopeActives($query)
    {
        return $query->where('date_limite', '>=', now()->toDateString());
    }

    /**
     * Scope : échéances déjà dépassées.
     */
    public function scopeEchues($query)
    {
        return $query->where('date_limite', '<', now()->toDateString());
    }

    /**
     * Scope : échéances à venir dans les N prochains jours.
     */
    public function scopeProchaines($query, int $jours = 7)
    {
        return $query->whereBetween('date_limite', [
            now()->toDateString(),
            now()->addDays($jours)->toDateString(),
        ]);
    }
}