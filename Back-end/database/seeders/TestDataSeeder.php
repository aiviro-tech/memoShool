<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Ecole;
use App\Models\MembreEcole;
use App\Models\CodeInvitation;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class TestDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Créer un admin utilisateur d'abord
        $testEmail = 'admin+' . time() . '@lnt.test';
        $adminEcole = User::create([
            'first_name' => 'Jean',
            'last_name' => 'Dupont',
            'email' => $testEmail,
            'password' => Hash::make('password'),
            'role' => 'admin_ecole',
            'date_of_birth' => '1985-03-15',
            'gender' => 'M',
            'nationality' => 'Béninoise',
            'phone' => '+229 66 11 11 11',
            'email_verified_at' => now(),
        ]);

        // 2. Créer une école test
        $ecole = Ecole::create([
            'nom_officiel' => 'Lycée National de Test',
            'sigle' => 'LNT',
            'site_web' => 'https://lnt.test',
            'adresse' => '123 Rue Test, Cotonou',
            'ville' => 'Cotonou',
            'code_postal' => '0001',
            'pays' => 'Bénin',
            'email_principal' => 'contact@lnt.test',
            'email_secondaire' => 'support@lnt.test',
            'tel_fixe' => '+229 21 00 00 00',
            'tel_mobile' => '+229 66 00 00 00',
            'nom_responsable' => 'Jean Dupont',
            'titre_responsable' => 'Directeur',
            'numero_rne' => 'RNE001',
            'type_etablissement' => 'lycee',
            'description_courte' => 'Un lycée d\'excellece pour tester',
            'description_complete' => 'Lycée National de Test est une institution dédiée à l\'excellence académique.',
            'max_etudiants' => 1000,
            'max_enseignants' => 150,
            'statut' => 'active',
            'admin_id' => $adminEcole->id,
        ]);

        // 3. Ajouter l'admin à l'école (statut actif)
        MembreEcole::create([
            'user_id' => $adminEcole->id,
            'ecole_id' => $ecole->id,
            'role' => 'admin',
            'statut' => 'actif',
            'validated_by' => null, // Auto-admin
            'validated_at' => now(),
            'joined_at' => now(),
        ]);

        // 4. Créer les 3 codes d'invitation de base
        $roles = [ 
            ['role' => 'etudiant', 'prefix' => 'ETU'],
            ['role' => 'enseignant', 'prefix' => 'ENS'],
            ['role' => 'admin', 'prefix' => 'ADM'],
        ];

        foreach ($roles as $item) {
            $code = $item['prefix'] . '-' . str_pad(random_int(0, 99999), 5, '0', STR_PAD_LEFT);
            CodeInvitation::create([
                'ecole_id' => $ecole->id,
                'role' => $item['role'],
                'code' => $code,
                'destinataire' => null,
                'utilise' => false,
                'genere_par' => $adminEcole->id,
            ]);
        }

        echo "TestData: École de test créée avec succès!\n";
        echo "Admin email: $testEmail | Password: password\n";
        echo "Codes invitation:\n";
        foreach (CodeInvitation::where('ecole_id', $ecole->id)->get() as $c) {
            echo "  {$c->role}: {$c->code}\n";
        }
    }
}
