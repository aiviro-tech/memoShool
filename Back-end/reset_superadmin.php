<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

// Verifier si le compte existe deja
$existing = User::where('email', 'roamoussou@gmail.com')->first();
if ($existing) {
    // Mettre a jour le role et le mot de passe
    $existing->update([
        'role'       => 'super_admin',
        'password'   => Hash::make('Rona2306'),
        'email_verified_at' => now(),
    ]);
    echo "Compte existant mis a jour en super_admin.\n";
    echo "ID: {$existing->id}\n";
    echo "Email: {$existing->email}\n";
} else {
    // Creer le nouveau
    $user = User::create([
        'first_name' => 'Ronaldo',
        'last_name'  => 'Amoussou',
        'email'      => 'roamoussou@gmail.com',
        'role'       => 'super_admin',
        'email_verified_at' => now(),
        'password'   => Hash::make('Rona2306'),
    ]);
    echo "Nouveau super admin cree.\n";
    echo "ID: {$user->id}\n";
    echo "Email: {$user->email}\n";
}

echo "\n=== CONNEXION ===\n";
echo "Email: roamoussou@gmail.com\n";
echo "Mot de passe: Rona2306\n";
echo "Role: super_admin\n";
