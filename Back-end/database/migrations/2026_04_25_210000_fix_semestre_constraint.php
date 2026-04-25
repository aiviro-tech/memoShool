<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Pour SQLite, la seule façon de supprimer un CHECK constraint est de recréer la table
        // On récupère toutes les données, drop la table, la recrée sans CHECK, et réinsère

        // 1. Sauvegarder les données existantes
        $existingData = DB::table('cours')->get();

        // 2. Désactiver les foreign keys
        DB::statement('PRAGMA foreign_keys = OFF');

        // 3. Drop la table
        Schema::dropIfExists('cours');

        // 4. Recréer la table avec semestre en VARCHAR (pas enum)
        DB::statement('
            CREATE TABLE "cours" (
                "id" integer primary key autoincrement not null,
                "ecole_id" integer not null,
                "matiere_id" integer not null,
                "enseignant_id" integer not null,
                "salle_id" integer not null,
                "classe_id" integer not null,
                "date_cours" date not null,
                "heure_debut" time not null,
                "heure_fin" time not null,
                "statut" varchar check ("statut" in (\'planifie\', \'confirme\', \'annule\', \'reporte\', \'termine\')) not null,
                "motif_annulation" text,
                "notes" text,
                "annee_academique" varchar not null,
                "semestre" varchar not null default \'S1\',
                "created_by" integer,
                "created_at" datetime,
                "updated_at" datetime,
                "deleted_at" datetime,
                foreign key("ecole_id") references "ecoles"("id") on delete cascade,
                foreign key("matiere_id") references "matieres"("id") on delete cascade,
                foreign key("enseignant_id") references "users"("id") on delete cascade,
                foreign key("salle_id") references "salles"("id") on delete cascade,
                foreign key("classe_id") references "classes"("id") on delete cascade,
                foreign key("created_by") references "users"("id") on delete set null
            )
        ');

        // 5. Réinsérer les données
        foreach ($existingData as $row) {
            DB::table('cours')->insert((array) $row);
        }

        // 6. Réactiver les foreign keys
        DB::statement('PRAGMA foreign_keys = ON');
    }

    public function down(): void
    {
        // Pas de rollback facile
    }
};
