<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('inscriptions', function (Blueprint $table) {
            $table->id();
            $table->string('annee_academique', 9);
            $table->date('date_inscription');
            $table->enum('statut', ['soumise', 'validee', 'rejetee'])
                  ->default('soumise');
            $table->text('motif_rejet')
                  ->nullable();
            $table->foreignId('etudiant_id')
                  ->constrained('users')
                  ->cascadeOnDelete();
            $table->foreignId('classe_id')
                  ->constrained('classes')
                  ->cascadeOnDelete();
            $table->unique(['etudiant_id', 'classe_id', 'annee_academique']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('inscriptions');
    }
};
