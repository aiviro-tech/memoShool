<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use App\Models\MembreEcole;
use App\Models\Ecole;

$user = User::where('email', 'admin@example.com')->first();
if (!$user) {
    $user = User::where('email', 'audrey20@gmail.com')->first();
    if ($user) {
        echo 'Found admin user: ' . $user->id . ' - ' . $user->email . PHP_EOL;
    }
}
if ($user) {
    echo 'User found: ' . $user->id . ' - ' . $user->email . PHP_EOL;
    $membre = MembreEcole::where('user_id', $user->id)->where('role', 'admin')->where('statut', 'actif')->first();
    if ($membre) {
        echo 'Admin membership found for ecole_id: ' . $membre->ecole_id . PHP_EOL;
        $demandes = MembreEcole::where('ecole_id', $membre->ecole_id)->where('statut', 'en_attente')->count();
        echo 'Pending requests: ' . $demandes . PHP_EOL;
    } else {
        echo 'No active admin membership found' . PHP_EOL;
    }
} else {
    echo 'User not found - trying first user...' . PHP_EOL;
    $user = User::first();
    if ($user) {
        echo 'First user: ' . $user->id . ' - ' . $user->email . PHP_EOL;
        $membre = MembreEcole::where('user_id', $user->id)->where('role', 'admin')->where('statut', 'actif')->first();
        if ($membre) {
            echo 'Admin membership found for ecole_id: ' . $membre->ecole_id . PHP_EOL;
            $demandes = MembreEcole::where('ecole_id', $membre->ecole_id)->where('statut', 'en_attente')->count();
            echo 'Pending requests: ' . $demandes . PHP_EOL;
        } else {
            echo 'No active admin membership found' . PHP_EOL;
        }
    }
}

$ecoles = Ecole::all();
echo 'Total écoles: ' . $ecoles->count() . PHP_EOL;
foreach ($ecoles as $ecole) {
    echo 'École: ' . $ecole->id . ' - ' . $ecole->nom_officiel . ' - Statut: ' . $ecole->statut . PHP_EOL;

    // Check admin membership
    $membre = MembreEcole::where('ecole_id', $ecole->id)->where('role', 'admin')->where('statut', 'actif')->first();
    if ($membre) {
        echo '  └─ Admin: ' . $membre->user->email . PHP_EOL;

        // Check pending requests
        $demandes = MembreEcole::where('ecole_id', $ecole->id)->where('statut', 'en_attente')->count();
        echo '  └─ Demandes en attente: ' . $demandes . PHP_EOL;
    } else {
        echo '  └─ Pas d\'admin actif' . PHP_EOL;
    }
    echo PHP_EOL;
}