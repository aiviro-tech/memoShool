<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('devoir_id')->constrained('devoirs')->cascadeOnDelete();
            $table->foreignId('etudiant_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('valeur', 5, 2);              // note obtenue
            $table->text('observation')->nullable();       // commentaire de l'enseignant
            $table->boolean('absent')->default(false);     // absent à l'évaluation
            $table->timestamps();

            // Un étudiant ne peut avoir qu'une seule note par devoir
            $table->unique(['devoir_id', 'etudiant_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notes');
    }
};