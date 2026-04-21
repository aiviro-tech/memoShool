<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('etudiant_classe', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                  ->constrained('users')
                  ->onDelete('cascade');
            $table->foreignId('classe_id')
                  ->constrained('classes')
                  ->onDelete('cascade');
            $table->string('annee_academique'); // ex: 2024-2025
            $table->timestamps();

            // Un étudiant ne peut pas être inscrit deux fois dans la même classe la même année
            $table->unique(['user_id', 'classe_id', 'annee_academique']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('etudiant_classe');
    }
};