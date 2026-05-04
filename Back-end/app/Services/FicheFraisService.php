<?php

namespace App\Services;

use App\Models\Inscription;
use App\Models\EcheanceClasse;
use App\Models\Paiement;
use Barryvdh\DomPDF\Facade\Pdf;

class FicheFraisService
{
    public function generer(int $inscription_id): array
    {
        $inscription = Inscription::with([
            'etudiant',
            'classe.filiere.ecole',
            'classe.typesFrais',
        ])->findOrFail($inscription_id);

        $etudiant = $inscription->etudiant;
        $classe   = $inscription->classe;
        $ecole    = $classe->filiere->ecole;

        // Échéances de la classe
        $echeances = EcheanceClasse::where('classe_id', $classe->id)
            ->orderBy('numero')
            ->get();

        // Types de frais
        $typesFrais = $classe->typesFrais;

        // Calcul du bilan
        $montantTotal = $typesFrais->where('obligatoire', true)->sum('montant');
        $montantPaye  = Paiement::where('inscription_id', $inscription->id)
            ->where('statut', 'approved')
            ->sum('montant');
        $soldeRestant = $montantTotal - $montantPaye;

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
                'filiere'          => $classe->filiere->nom,
            ],
            'types_frais'   => $typesFrais,
            'echeances'     => $echeances,
            'montant_total' => $montantTotal,
            'montant_paye'  => $montantPaye,
            'solde_restant' => $soldeRestant,
        ];

        // Créer le dossier si nécessaire
        $directory = storage_path('app/public/fiches');
        if (!file_exists($directory)) {
            mkdir($directory, 0755, true);
        }

        $pdf  = Pdf::loadView('fiches.frais', $donnees);
        $path = "fiches/fiche_frais_{$inscription_id}.pdf";
        $pdf->save(storage_path("app/public/{$path}"));

        return [
            'path'    => $path,
            'donnees' => $donnees,
        ];
    }
}