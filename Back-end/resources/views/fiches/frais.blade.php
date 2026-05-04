<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Fiche de Frais — {{ $etudiant['nom'] }} {{ $etudiant['prenom'] }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #333; margin: 30px; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #333; padding-bottom: 10px; }
        .header h1 { font-size: 16px; text-transform: uppercase; margin: 0; }
        .header h2 { font-size: 13px; margin: 5px 0; }

        .infos { margin-bottom: 20px; }
        .infos table { width: 100%; }
        .infos td { padding: 3px 5px; width: 50%; }
        .infos .label { font-weight: bold; }

        .section-title { 
            font-size: 13px; 
            font-weight: bold; 
            margin: 20px 0 8px 0;
            border-bottom: 1px solid #333;
            padding-bottom: 4px;
        }

        .frais-table, .echeances-table { 
            width: 100%; 
            border-collapse: collapse; 
            margin-bottom: 15px; 
        }
        .frais-table th, .echeances-table th { 
            background-color: #333; 
            color: white; 
            padding: 6px 8px; 
            text-align: left; 
            font-size: 11px; 
        }
        .frais-table td, .echeances-table td { 
            padding: 5px 8px; 
            border-bottom: 1px solid #ddd; 
            font-size: 11px; 
        }
        .frais-table tr.total-row { 
            font-weight: bold; 
            background-color: #f0f0f0; 
        }

        .bilan { margin-top: 20px; text-align: right; font-size: 12px; }
        .bilan .montant { font-weight: bold; font-size: 14px; }
        .solde-restant { color: red; }
        .solde-zero { color: green; }

        .footer { margin-top: 30px; border-top: 1px solid #333; padding-top: 10px; font-size: 10px; color: #666; text-align: center; }
    </style>
</head>
<body>

    {{-- En-tête --}}
    <div class="header">
        <h1>{{ $ecole['nom'] }} @if($ecole['sigle']) ({{ $ecole['sigle'] }}) @endif</h1>
        <h2>FICHE DE FRAIS SCOLAIRES</h2>
        <p>Année académique : {{ $inscription['annee_academique'] }}</p>
    </div>

    {{-- Infos étudiant --}}
    <div class="infos">
        <table>
            <tr>
                <td><span class="label">Nom :</span> {{ $etudiant['nom'] }}</td>
                <td><span class="label">Prénom :</span> {{ $etudiant['prenom'] }}</td>
            </tr>
            <tr>
                <td><span class="label">Classe :</span> {{ $inscription['classe'] }}</td>
                <td><span class="label">Filière :</span> {{ $inscription['filiere'] }}</td>
            </tr>
        </table>
    </div>

    {{-- Types de frais --}}
    <div class="section-title">Détail des frais</div>
    <table class="frais-table">
        <thead>
            <tr>
                <th>Désignation</th>
                <th>Obligatoire</th>
                <th style="text-align: right;">Montant</th>
            </tr>
        </thead>
        <tbody>
            @foreach($types_frais as $frais)
                <tr>
                    <td>{{ $frais->libelle }}</td>
                    <td>{{ $frais->obligatoire ? 'Oui' : 'Non' }}</td>
                    <td style="text-align: right;">
                        {{ number_format($frais->montant, 0, ',', ' ') }} FCFA
                    </td>
                </tr>
            @endforeach
            <tr class="total-row">
                <td colspan="2">TOTAL OBLIGATOIRE</td>
                <td style="text-align: right;">
                    {{ number_format($montant_total, 0, ',', ' ') }} FCFA
                </td>
            </tr>
        </tbody>
    </table>

    {{-- Échéances --}}
    @if($echeances->count() > 0)
        <div class="section-title">Calendrier des paiements</div>
        <table class="echeances-table">
            <thead>
                <tr>
                    <th>Tranche</th>
                    <th>Libellé</th>
                    <th style="text-align: right;">Date limite</th>
                    <th style="text-align: right;">Montant</th>
                </tr>
            </thead>
            <tbody>
                @foreach($echeances as $echeance)
                    <tr>
                        <td>{{ $echeance->numero }}</td>
                        <td>{{ $echeance->libelle ?? '—' }}</td>
                        <td style="text-align: right;">
                            {{ \Carbon\Carbon::parse($echeance->date_limite)->format('d/m/Y') }}
                        </td>
                        <td style="text-align: right;">
                            {{ number_format($echeance->montant, 0, ',', ' ') }} FCFA
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    {{-- Bilan --}}
    <div class="bilan">
        <p>Total scolarité : <span class="montant">{{ number_format($montant_total, 0, ',', ' ') }} FCFA</span></p>
        <p>Total payé : <span class="montant">{{ number_format($montant_paye, 0, ',', ' ') }} FCFA</span></p>
        <p>
            Solde restant :
            <span class="montant {{ $solde_restant > 0 ? 'solde-restant' : 'solde-zero' }}">
                {{ number_format($solde_restant, 0, ',', ' ') }} FCFA
            </span>
        </p>
    </div>

    {{-- Pied de page --}}
    <div class="footer">
        Document généré le {{ now()->format('d/m/Y à H:i') }} —
        {{ $ecole['nom'] }} — Document non officiel
    </div>

</body>
</html>