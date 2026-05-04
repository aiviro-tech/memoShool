<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Relevé de Notes — {{ $etudiant['nom'] }} {{ $etudiant['prenom'] }}</title>
    <style>
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 12px;
            color: #333;
            margin: 20px;
        }

        /* En-tête */
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #333;
            padding-bottom: 10px;
        }
        .header h1 {
            font-size: 16px;
            text-transform: uppercase;
            margin: 0;
        }
        .header h2 {
            font-size: 13px;
            margin: 5px 0;
        }

        /* Infos étudiant */
        .infos {
            margin-bottom: 20px;
        }
        .infos table {
            width: 100%;
        }
        .infos td {
            padding: 3px 5px;
            width: 50%;
        }
        .infos .label {
            font-weight: bold;
        }

        /* Tableau des notes */
        .notes-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        .notes-table th {
            background-color: #333;
            color: white;
            padding: 6px 8px;
            text-align: left;
            font-size: 11px;
        }
        .notes-table td {
            padding: 5px 8px;
            border-bottom: 1px solid #ddd;
            font-size: 11px;
        }
        .notes-table tr.ue-row {
            background-color: #f0f0f0;
            font-weight: bold;
        }
        .notes-table tr.ecue-row {
            background-color: #ffffff;
        }
        .notes-table tr.ecue-row td:first-child {
            padding-left: 20px;
        }

        /* Statuts */
        .statut-valide    { color: green; font-weight: bold; }
        .statut-rattrapage { color: orange; font-weight: bold; }
        .statut-non_valide { color: red; font-weight: bold; }

        /* Moyenne générale */
        .moyenne-generale {
            margin-top: 15px;
            text-align: right;
            font-size: 13px;
        }
        .moyenne-generale span {
            font-weight: bold;
            font-size: 15px;
        }

        /* Pied de page */
        .footer {
            margin-top: 30px;
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
        <h1>{{ $ecole['nom'] }} @if($ecole['sigle']) ({{ $ecole['sigle'] }}) @endif</h1>
        <h2>RELEVÉ DE NOTES</h2>
        <p>
            Année académique : {{ $semestre['annee_academique'] }} —
            Semestre {{ $semestre['numero'] }} —
            Session {{ $session }}
        </p>
    </div>

    {{-- Infos étudiant --}}
    <div class="infos">
        <table>
            <tr>
                <td><span class="label">Nom :</span> {{ strtoupper($etudiant['nom']) }}</td>
                <td><span class="label">Prénom :</span> {{ $etudiant['prenom'] }}</td>
            </tr>
            <tr>
                <td><span class="label">Matricule :</span> {{ $etudiant['matricule'] }}</td>
                <td><span class="label">Classe :</span> {{ $classe['nom'] }} — {{ $classe['filiere'] }}</td>
            </tr>
        </table>
    </div>

    {{-- Tableau des notes --}}
    <table class="notes-table">
        <thead>
            <tr>
                <th>Matière</th>
                <th>Crédits</th>
                <th>Moy. CC</th>
                <th>Note Examen</th>
                <th>Moyenne</th>
                <th>Statut</th>
            </tr>
        </thead>
        <tbody>
            @foreach($ues as $ue)
                {{-- Ligne UE --}}
                <tr class="ue-row">
                    <td colspan="4">{{ $ue['ue_nom'] ?? 'UE #' . $ue['ue_id'] }}</td>
                    <td>{{ number_format($ue['moyenne_ue'], 2) }}/20</td>
                    <td class="statut-{{ $ue['validee'] ? 'valide' : 'non_valide' }}">
                        {{ $ue['validee'] ? 'Validée' : 'Non validée' }}
                    </td>
                </tr>

                {{-- Lignes ECUE --}}
                @foreach($ue['ecues'] as $ecue)
                    <tr class="ecue-row">
                        <td>{{ $ecue['ecue_nom'] }}</td>
                        <td>{{ $ecue['credits'] }}</td>
                        <td>
                            {{ $ecue['moyenne_cc'] !== null
                                ? number_format($ecue['moyenne_cc'], 2)
                                : '—' }}
                        </td>
                        <td>
                            @if($ecue['absent_examen'])
                                Absent
                            @elseif($ecue['note_examen'] !== null)
                                {{ number_format($ecue['note_examen'], 2) }}
                            @else
                                —
                            @endif
                        </td>
                        <td>{{ number_format($ecue['moyenne'], 2) }}/20</td>
                        <td class="statut-{{ $ecue['statut'] }}">
                            @switch($ecue['statut'])
                                @case('valide')      Validé @break
                                @case('rattrapage')  Rattrapage @break
                                @case('non_valide')  Non validé @break
                                @case('incomplet')   Incomplet @break
                                @default             — @break
                            @endswitch
                        </td>
                    </tr>
                @endforeach
            @endforeach
        </tbody>
    </table>

    {{-- Moyenne générale --}}
    <div class="moyenne-generale">
        Moyenne générale du semestre :
        <span>{{ number_format($moyenne_generale, 2) }}/20</span>
        &nbsp;&nbsp;|&nbsp;&nbsp;
        Statut :
        <span class="statut-{{ $statut }}">
            @switch($statut)
                @case('valide')     Semestre validé @break
                @case('rattrapage') Rattrapage @break
                @default            — @break
            @endswitch
        </span>
    </div>

    {{-- Pied de page --}}
    <div class="footer">
        Relevé généré le {{ now()->format('d/m/Y à H:i') }} —
        {{ $ecole['nom'] }} — Document non officiel sans cachet
    </div>

</body>
</html>