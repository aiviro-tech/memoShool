<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('classes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')
                  ->constrained('ecoles')
                  ->onDelete('cascade');
            $table->string('nom');
            $table->string('code')->unique();
            $table->enum('niveau', ['L1','L2','L3','M1','M2']);
            $table->foreignId('filiere_id')
                  ->constrained('filieres')
                  ->onDelete('cascade');
            $table->string('annee_academique');
            $table->boolean('actif')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};