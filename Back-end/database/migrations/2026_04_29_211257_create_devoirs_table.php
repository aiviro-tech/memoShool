<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devoirs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('ecue_id')->constrained('ecues')->cascadeOnDelete();
            $table->foreignId('classe_id')->constrained('classes')->cascadeOnDelete();
            $table->foreignId('enseignant_id')->constrained('users')->cascadeOnDelete();
            $table->string('titre');
            $table->enum('type', ['CC', 'TP', 'TD', 'EXAMEN']);
            $table->unsignedTinyInteger('session')->default(1); // 1 ou 2
            $table->decimal('bareme', 5, 2)->default(20.00);   // noté sur combien
            $table->date('date_evaluation');
            $table->unsignedSmallInteger('duree')->nullable();  // durée en minutes
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devoirs');
    }
};