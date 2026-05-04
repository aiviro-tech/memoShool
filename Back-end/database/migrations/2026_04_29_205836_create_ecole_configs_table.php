<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ecole_configs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->unique()->constrained('ecoles')->cascadeOnDelete();

            // Section 1 — Configuration Pédagogique
            // Calcul des notes
            $table->unsignedTinyInteger('poids_cc')->default(40);         // % CC
            $table->unsignedTinyInteger('poids_examen')->default(60);     // % Examen
            $table->decimal('note_minimale_examen', 4, 2)->default(5.00); // note éliminatoire
            $table->decimal('moyenne_validation_ue', 4, 2)->default(10.00);
            $table->boolean('rattrapage_note_100_pourcent')->default(true);

            // Crédits & progression
            $table->unsignedTinyInteger('credits_par_semestre')->default(30);
            $table->unsignedTinyInteger('seuil_enjambement_pourcent')->default(80);
            $table->unsignedTinyInteger('nombre_sessions')->default(2);

            // Section 2 — Assiduité & Absences
            $table->unsignedTinyInteger('absences_max_par_ecue')->default(3);
            $table->unsignedTinyInteger('absences_max_par_semestre')->default(10);
            $table->unsignedSmallInteger('heures_absence_exclusion_s1_s2')->default(150);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ecole_configs');
    }
};