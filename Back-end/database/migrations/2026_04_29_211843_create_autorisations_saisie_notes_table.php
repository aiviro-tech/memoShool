<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('autorisations_saisie_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('enseignant_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('autorise_par')->constrained('users')->cascadeOnDelete();
            $table->foreignId('semestre_id')->constrained('semestres')->cascadeOnDelete();
            $table->boolean('actif')->default(true);
            $table->timestamp('date_autorisation');
            $table->timestamp('date_expiration')->nullable(); // null = pas de limite
            $table->text('observation')->nullable();
            $table->timestamps();

            // Un enseignant ne peut avoir qu'une seule autorisation active par semestre
            $table->unique(['enseignant_id', 'semestre_id', 'ecole_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('autorisations_saisie_notes');
    }
};