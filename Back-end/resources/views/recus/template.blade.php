<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Reçu N° {{ $paiement['numero_recu'] }}</title>
    <style>
        body { 
            font-family: DejaVu Sans, sans-serif;
            font-size: 12px; 
            color: #333; 
            margin: 30px; 
        }
        .header { 
            display: flex; 
            justify-content: space-between; 
            margin-bottom: 20px; 
            border-bottom: 2px solid #333; 
            padding-bottom: 10px; 
        }
        .header-left h1 { 
            font-size: 14px; 
            text-transform: uppercase; 
            margin: 0; 
        }
        .header-left p { 
            margin: 2px 0; 
            font-size: 10px; 
        }
        .header-right { 
            text-align: right; 
            font-size: 12px; 
        }
        .numero-recu { 
            font-size: 14px; 
            font-weight: bold; 
        }
        .champ { 
            margin: 15px 0; 
            border-bottom: 1px dotted #999; 
            padding-bottom: 5px; 
        }
        .champ .label { 
            font-weight: bold; 
            margin-right: 10px; 
        }
        .champ .valeur { 
            font-size: 13px; 
        }
        .montant-chiffres { 
            font-size: 16px; 
            font-weight: bold; 
            text-align: right; 
        }
        .bilan { 
            margin-top: 20px; 
            text-align: right; 
            font-size: 11px; 
        }
        .bilan .montant { 
            font-weight: bold; 
        }
        .solde-restant { 
            color: red; 
        }
        .solde-zero { 
            color: green; 
        }
        .signature { 
            margin-top: 40px; 
            text-align: right; 
        }
        .footer { 
            margin-top: 20px; 
            border-top: 1px solid #333; 
            padding-top: 10px; 
            font-size: 10px; 
            color: #666; 
            text-align: center; 
        }
    </style>
</head>
<body>

    {{-- En-tête --}}
    <div class="header">
        <div class="header-left">
            <h1>{{ $ecole['nom'] }} @if($ecole['sigle']) ({{ $ecole['sigle'] }}) @endif</h1>
            <p>{{ $ecole['ville'] }}, {{ $ecole['pays'] }}</p>
        </div>
        <div class="header-right">
            <p class="numero-recu">N° : {{ $paiement['numero_recu'] }}</p>
            <p>Année académique : {{ $inscription['annee_academique'] }}</p>
        </div>
    </div>

    {{-- Montant en chiffres --}}
    <div class="montant-chiffres">
        B.P.F. {{ number_format($paiement['montant'], 0, ',', ' ') }} FCFA
    </div>

    {{-- Reçu de --}}
    <div class="champ">
        <span class="label">Reçu de :</span>
        <span class="valeur">{{ $etudiant['nom'] }} {{ $etudiant['prenom'] }}</span>
    </div>

    {{-- La somme de --}}
    <div class="champ">
        <span class="label">La somme de :</span>
        <span class="valeur">{{ $paiement['montant_en_lettres'] }}</span>
    </div>

    {{-- Objet --}}
    <div class="champ">
        <span class="label">Objet :</span>
        <span class="valeur">{{ $paiement['objet'] }}</span>
    </div>

    {{-- Classe --}}
    <div class="champ">
        <span class="label">Classe :</span>
        <span class="valeur">{{ $inscription['classe'] }}</span>
    </div>

    {{-- Mode de paiement & Transaction --}}
    <div class="champ">
        <span class="label">Mode :</span>
        <span class="valeur">
            @switch($paiement['mode_paiement'])
                @case('mtn_money')  MTN Mobile Money @break
                @case('moov_money') Moov Money @break
                @default            — @break
            @endswitch
        </span>
        &nbsp;&nbsp;|&nbsp;&nbsp;
        <span class="label">Réf. FedaPay :</span>
        <span class="valeur">{{ $paiement['fedapay_transaction_id'] ?? '—' }}</span>
    </div>

    {{-- Bilan financier --}}
    <div class="bilan">
        <p>Total scolarité : 
            <span class="montant">
                {{ number_format($bilan['montant_total'], 0, ',', ' ') }} FCFA
            </span>
        </p>
        <p>Montant payé ce jour : 
            <span class="montant">
                {{ number_format($bilan['montant_ce_jour'], 0, ',', ' ') }} FCFA
            </span>
        </p>
        <p>Total payé à ce jour : 
            <span class="montant">
                {{ number_format($bilan['total_paye'], 0, ',', ' ') }} FCFA
            </span>
        </p>
        <p>Solde restant : 
            <span class="montant {{ $bilan['solde_restant'] > 0 ? 'solde-restant' : 'solde-zero' }}">
                {{ number_format($bilan['solde_restant'], 0, ',', ' ') }} FCFA
            </span>
        </p>
    </div>

    {{-- Date & Signature --}}
    <div class="signature">
        <p>{{ $ecole['ville'] }}, le {{ $paiement['date_paiement'] }}</p>
        <p>Signature et Cachet</p>
        <br><br>
    </div>

    {{-- Pied de page --}}
    <div class="footer">
        Reçu généré automatiquement le {{ now()->format('d/m/Y à H:i') }} —
        {{ $ecole['nom'] }} — Document officiel
    </div>

</body>
</html>