<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('semestres', function (Blueprint $table) {
            $table->id();
            
            $table->foreignId('filiere_id')
                  ->constrained('filieres')
                  ->onDelete('cascade');

            $table->string('numero', 5);                    // S1, S2, S3, ..., S10
            $table->string('annee_academique', 9);          // ex: 2025-2026
            $table->date('date_debut')->nullable();
            $table->date('date_fin')->nullable();
            $table->text('description')->nullable();

            $table->timestamps();

            // Unicité : une filière ne peut pas avoir deux fois le même semestre dans la même année académique
            $table->unique(['filiere_id', 'numero', 'annee_academique']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('semestres');
    }
};