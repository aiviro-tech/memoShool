<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Pour SQLite, on doit recréer la table car ALTER COLUMN n'est pas supporté
        // On va donc supprimer la contrainte CHECK en recréant la colonne

        // Étape 1: Renommer la colonne existante
        Schema::table('cours', function (Blueprint $table) {
            $table->renameColumn('semestre', 'semestre_old');
        });

        // Étape 2: Créer la nouvelle colonne sans contrainte CHECK restrictive
        Schema::table('cours', function (Blueprint $table) {
            $table->string('semestre', 5)->default('S1')->after('annee_academique');
        });

        // Étape 3: Copier les données
        DB::statement('UPDATE cours SET semestre = semestre_old');

        // Étape 4: Supprimer l'ancienne colonne
        Schema::table('cours', function (Blueprint $table) {
            $table->dropColumn('semestre_old');
        });
    }

    public function down(): void
    {
        Schema::table('cours', function (Blueprint $table) {
            // On ne peut pas facilement revenir à un enum avec SQLite
            // Laisser en string
        });
    }
};
