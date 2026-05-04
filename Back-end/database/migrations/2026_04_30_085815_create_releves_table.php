<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('releves', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('etudiant_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('semestre_id')->constrained('semestres')->cascadeOnDelete();
            $table->foreignId('classe_id')->constrained('classes')->cascadeOnDelete();
            $table->unsignedTinyInteger('session')->default(1);   // session 1 ou 2
            $table->decimal('moyenne_generale', 5, 2);
            $table->enum('statut', ['valide', 'rattrapage', 'non_valide']);
            $table->string('fichier_path')->nullable();           // chemin du PDF généré
            $table->timestamp('date_generation')->nullable();
            $table->timestamps();

            // Un seul relevé par étudiant par semestre par session
            $table->unique(['etudiant_id', 'semestre_id', 'session']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('releves');
    }
};