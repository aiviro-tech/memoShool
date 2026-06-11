<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

$email = 'validator@memoshool.local';
$password = 'Validator2026!';

// Vérifier si le compte existe déjà
$existing = User::where('email', $email)->first();
if ($existing) {
    $existing->update([
        'role' => 'super_admin',
        'password' => Hash::make($password),
        'email_verified_at' => now(),
    ]);
    echo "Compte existant mis à jour en super_admin.\n";
    echo "ID: {$existing->id}\n";
    echo "Email: {$existing->email}\n";
} else {
    $user = User::create([
        'first_name' => 'Validator',
        'last_name'  => 'Admin',
        'email'      => $email,
        'role'       => 'super_admin',
        'email_verified_at' => now(),
        'password'   => Hash::make($password),
    ]);
    echo "Nouveau super admin (validateur) créé.\n";
    echo "ID: {$user->id}\n";
    echo "Email: {$user->email}\n";
}

echo "\n=== CONNEXION ===\n";
echo "Email: {$email}\n";
echo "Mot de passe: {$password}\n";
echo "Role: super_admin\n";

echo "\nRemarque: changez le mot de passe immédiatement après connexion.\n";
