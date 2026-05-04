<?php

namespace App\Console\Commands;

use App\Models\EcheanceClasse;
use App\Models\Inscription;
use App\Models\Paiement;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class RappelEcheancePaiement extends Command
{
    protected $signature   = 'rappel:echeances';
    protected $description = 'Envoyer des rappels pour les échéances de paiement qui approchent';

    public function handle(): void
    {
        $notificationService = new NotificationService();
        $aujourd_hui         = Carbon::today();

        // Récupérer les échéances dans 3 jours et dans 1 jour
        $echeances = EcheanceClasse::whereIn('date_limite', [
            $aujourd_hui->copy()->addDays(3)->toDateString(),
            $aujourd_hui->copy()->addDays(1)->toDateString(),
        ])->get();

        foreach ($echeances as $echeance) {
            // Récupérer les inscriptions actives pour cette classe
            $inscriptions = Inscription::with(['etudiant', 'classe.typesFrais'])
                ->where('classe_id', $echeance->classe_id)
                ->where('statut', 'validee')
                ->get();

            foreach ($inscriptions as $inscription) {
                // Calculer le solde restant
                $montantTotal = $inscription->classe->typesFrais
                    ->where('obligatoire', true)
                    ->sum('montant');

                $montantPaye = Paiement::where('inscription_id', $inscription->id)
                    ->where('statut', 'approved')
                    ->sum('montant');

                $soldeRestant = $montantTotal - $montantPaye;

                // Ne notifier que si l'étudiant a encore un solde à payer
                if ($soldeRestant > 0) {
                    $ecoleId = $inscription->classe->filiere->ecole_id ?? null;

                    $joursRestants = $aujourd_hui->diffInDays(
                        Carbon::parse($echeance->date_limite)
                    );

                    $notificationService->notifierEcheancePaiement(
                        $inscription->etudiant_id,
                        $ecoleId,
                        Carbon::parse($echeance->date_limite)->format('d/m/Y'),
                        $soldeRestant,
                        $echeance->libelle ?? "Échéance {$echeance->numero}"
                    );

                    $this->info("Rappel envoyé à l'étudiant ID {$inscription->etudiant_id} — Solde restant : {$soldeRestant} FCFA");
                }
            }
        }

        $this->info('Rappels d\'échéances envoyés avec succès.');
    }
}