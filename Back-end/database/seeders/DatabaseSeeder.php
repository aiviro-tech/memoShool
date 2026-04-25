<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        // Super Admin
        User::create([
            'first_name' => 'Super',
            'last_name' => 'Admin',
            'email' => 'superadmin2026@gmail.com',
            'role' => 'super_admin',
            'email_verified_at' => now(),
            'password' => Hash::make('estro2026'),
        ]);

        // Test User
        User::create([
            'first_name' => 'Test',
            'last_name' => 'User',
            'email' => 'test@example.com',
            'email_verified_at' => now(),
            'role' => 'etudiant',
            'password' => Hash::make('password'),
        ]);
    }
}
