<?php

namespace App\Services;

use App\Models\Classe;
use App\Models\Releve;
use App\Models\Semestre;
use App\Models\Ue;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;

class ReleveGeneratorService
{
    private MoyenneCalculatorService $moyenneService;

    public function __construct(int $ecole_id)
    {
        $this->moyenneService = new MoyenneCalculatorService($ecole_id);
    }

    /**
     * Générer le relevé de notes d'un étudiant pour un semestre.
     *
     * CORRECTIONS :
     * 1. Création automatique du dossier storage/app/public/releves/
     *    → évite "Failed to open stream: No such file or directory"
     *
     * 2. Mapping du statut vers les valeurs acceptées par la migration :
     *    enum('valide', 'rattrapage', 'non_valide')
     *    MoyenneCalculatorService peut retourner 'en_attente' si aucune note
     *    n'est encore saisie → CHECK constraint violation sans ce mapping.
     *
     * 3. moyenne_generale est NOT NULL en base (decimal).
     *    MoyenneCalculatorService retourne null si rien évalué → on stocke 0.00.
     */
    public function generer(int $etudiant_id, int $semestre_id, int $classe_id, int $session = 1): array
    {
        $etudiant = User::findOrFail($etudiant_id);
        $semestre = Semestre::with(['filiere.ecole'])->findOrFail($semestre_id);
        $classe   = Classe::with('filiere.ecole')->findOrFail($classe_id);

        // Calcul des moyennes
        $resultatSemestre = $this->moyenneService->calculerMoyenneSemestre(
            $etudiant_id,
            $semestre_id,
            $classe_id,
            $session
        );

        // Enrichir les UE avec leurs noms
        $ues = collect($resultatSemestre['ues'])->map(function ($ue) {
            $ueModel = Ue::find($ue['ue_id']);
            return array_merge($ue, [
                'ue_nom' => $ueModel ? $ueModel->libelle : 'UE #' . $ue['ue_id'],
            ]);
        })->toArray();

        // Données pour le template Blade
        $donnees = [
            'etudiant' => [
                'id'        => $etudiant->id,
                'nom'       => $etudiant->last_name,
                'prenom'    => $etudiant->first_name,
                'matricule' => $etudiant->matricule ?? 'N/A',
            ],
            'ecole' => [
                'nom'   => $classe->filiere->ecole->nom_officiel ?? 'N/A',
                'sigle' => $classe->filiere->ecole->sigle ?? '',
            ],
            'classe' => [
                'nom'     => $classe->nom,
                'filiere' => $classe->filiere->nom,
            ],
            'semestre' => [
                'numero'           => $semestre->numero,
                'annee_academique' => $semestre->annee_academique,
            ],
            'session'          => $session,
            'moyenne_generale' => $resultatSemestre['moyenne'],
            'statut'           => $resultatSemestre['statut'],
            'ues'              => $ues,
        ];

        // CORRECTION 1 : créer le dossier automatiquement s'il n'existe pas
        $dossierReleves = storage_path('app/public/releves');
        if (!file_exists($dossierReleves)) {
            mkdir($dossierReleves, 0755, true);
        }

        // Générer le PDF
        $pdf  = Pdf::loadView('releves.template', $donnees);
        $path = "releves/releve_{$etudiant_id}_s{$semestre_id}_session{$session}.pdf";
        $pdf->save(storage_path("app/public/{$path}"));

        // CORRECTION 2 : mapper le statut vers les valeurs du enum en base
        // Valeurs acceptées : 'valide', 'rattrapage', 'non_valide'
        // Valeurs possibles du service : 'valide', 'rattrapage', 'en_attente', 'non_valide'
        $statutBrut   = $resultatSemestre['statut'] ?? 'non_valide';
        $statutReleve = match($statutBrut) {
            'valide'     => 'valide',
            'rattrapage' => 'rattrapage',
            default      => 'non_valide', // 'en_attente' et tout autre → non_valide
        };

        // CORRECTION 3 : moyenne_generale NOT NULL en base → 0.00 si null
        $moyenneGenerale = $resultatSemestre['moyenne'] !== null
            ? round((float) $resultatSemestre['moyenne'], 2)
            : 0.00;

        // Sauvegarder en base
        $releve = Releve::updateOrCreate(
            [
                'etudiant_id' => $etudiant_id,
                'semestre_id' => $semestre_id,
                'session'     => $session,
            ],
            [
                'ecole_id'         => $classe->filiere->ecole->id,
                'classe_id'        => $classe_id,
                'moyenne_generale' => $moyenneGenerale,
                'statut'           => $statutReleve,
                'fichier_path'     => $path,
                'date_generation'  => now(),
            ]
        );

        return [
            'releve'  => $releve,
            'donnees' => $donnees,
            'path'    => $path,
        ];
    }
}