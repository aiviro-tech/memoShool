<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')
                  ->constrained('ecoles')
                  ->onDelete('cascade');
            $table->foreignId('matiere_id')
                  ->constrained('matieres')
                  ->onDelete('cascade');
            $table->foreignId('enseignant_id')
                  ->constrained('users')
                  ->onDelete('cascade');
            $table->foreignId('salle_id')
                  ->constrained('salles')
                  ->onDelete('cascade');
            $table->foreignId('classe_id')
                  ->constrained('classes')
                  ->onDelete('cascade');
            $table->date('date_cours');
            $table->time('heure_debut');
            $table->time('heure_fin');
            $table->enum('statut', [
                'planifie',
                'confirme',
                'annule',
                'reporte',
                'termine'
            ]);
            $table->text('motif_annulation')->nullable();
            $table->text('notes')->nullable();
            $table->string('annee_academique');
            $table->enum('semestre', ['S1', 'S2']);
            $table->foreignId('created_by')
                  ->nullable()
                  ->constrained('users')
                  ->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cours');
    }
};