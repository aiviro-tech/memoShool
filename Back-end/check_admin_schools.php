<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use App\Models\MembreEcole;
use App\Models\Ecole;

$user = User::where('email', 'audrey20@gmail.com')->first();
$membres = MembreEcole::where('user_id', $user->id)->where('role', 'admin')->where('statut', 'actif')->get();

foreach ($membres as $membre) {
    $ecole = Ecole::find($membre->ecole_id);
    echo 'Admin of ecole ' . $membre->ecole_id . ': ' . $ecole->nom_officiel . PHP_EOL;
    $demandes = MembreEcole::where('ecole_id', $membre->ecole_id)->where('statut', 'en_attente')->count();
    echo 'Pending requests: ' . $demandes . PHP_EOL;

    if ($demandes > 0) {
        $demandesDetails = MembreEcole::with('user')->where('ecole_id', $membre->ecole_id)->where('statut', 'en_attente')->get();
        foreach ($demandesDetails as $demande) {
            echo '  └─ ' . $demande->user->email . ' (' . $demande->role . ')' . PHP_EOL;
        }
    }
    echo PHP_EOL;
}