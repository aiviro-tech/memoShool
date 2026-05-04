<?php

namespace App\Services;

use App\Models\Paiement;
use Barryvdh\DomPDF\Facade\Pdf;
use NumberToWords\NumberToWords;

class RecuPaiementService
{
    /**
     * Convertir un montant en lettres (français).
     */
    private function montantEnLettres(float $montant): string
    {
        $numberToWords = new NumberToWords();
        $transformer   = $numberToWords->getNumberTransformer('fr');
        $lettres       = $transformer->toWords((int) $montant);
        return ucfirst($lettres) . ' francs CFA';
    }

    /**
     * Générer un numéro de reçu unique.
     */
    private function genererNumeroRecu(): string
    {
        $dernier = Paiement::whereNotNull('numero_recu')
            ->orderByDesc('id')
            ->first();

        if (!$dernier || !$dernier->numero_recu) {
            return 'REC-001';
        }

        $numero = (int) str_replace('REC-', '', $dernier->numero_recu);
        return 'REC-' . str_pad($numero + 1, 3, '0', STR_PAD_LEFT);
    }

    /**
     * Générer le reçu de paiement.
     */
    public function generer(int $paiement_id): array
    {
        $paiement = Paiement::with([
            'inscription.etudiant',
            'inscription.classe.filiere.ecole',
            'inscription.classe.typesFrais',
        ])->findOrFail($paiement_id);

        $inscription = $paiement->inscription;
        $etudiant    = $inscription->etudiant;
        $classe      = $inscription->classe;
        $ecole       = $classe->filiere->ecole;

        // Générer le numéro de reçu si pas encore fait
        if (!$paiement->numero_recu) {
            $numeroRecu = $this->genererNumeroRecu();
            $paiement->update(['numero_recu' => $numeroRecu]);
        } else {
            $numeroRecu = $paiement->numero_recu;
        }

        // Calcul du bilan — AVANT l'objet
        $montantTotal       = $classe->typesFrais->where('obligatoire', true)->sum('montant');
        $montantPaye        = $inscription->totalPaye();
        $soldeApresPaiement = $montantTotal - $montantPaye;

        // Objet dynamique
        $objet = $soldeApresPaiement > 0
            ? 'Paiement partiel des frais scolaires'
            : 'Paiement total des frais scolaires';

        $donnees = [
            'ecole' => [
                'nom'   => $ecole->nom_officiel ?? 'N/A',
                'sigle' => $ecole->sigle ?? '',
                'ville' => $ecole->ville ?? 'Cotonou',
                'pays'  => $ecole->pays ?? 'Bénin',
            ],
            'etudiant' => [
                'nom'    => strtoupper($etudiant->last_name),
                'prenom' => $etudiant->first_name,
            ],
            'inscription' => [
                'annee_academique' => $inscription->annee_academique,
                'classe'           => $classe->nom,
            ],
            'paiement' => [
                'numero_recu'            => $numeroRecu,
                'montant'                => $paiement->montant,
                'montant_en_lettres'     => $this->montantEnLettres($paiement->montant),
                'date_paiement'          => $paiement->date_paiement
                                            ? $paiement->date_paiement->format('d/m/Y')
                                            : now()->format('d/m/Y'),
                'mode_paiement'          => $paiement->mode_paiement,
                'reference_paiement'     => $paiement->reference_paiement,
                'fedapay_transaction_id' => $paiement->fedapay_transaction_id,
                'objet'                  => $objet,
            ],
            'bilan' => [
                'montant_total'   => $montantTotal,
                'montant_ce_jour' => $paiement->montant,
                'total_paye'      => $montantPaye,
                'solde_restant'   => $soldeApresPaiement,
            ],
        ];

        // Créer le dossier si nécessaire
        $directory = storage_path('app/public/recus');
        if (!file_exists($directory)) {
            mkdir($directory, 0755, true);
        }

        $pdf  = Pdf::loadView('recus.template', $donnees);
        $path = "recus/recu_paiement_{$paiement_id}.pdf";
        $pdf->save(storage_path("app/public/{$path}"));

        $paiement->update(['recu' => $path]);

        return [
            'paiement' => $paiement->fresh(),
            'path'     => $path,
        ];
    }
}