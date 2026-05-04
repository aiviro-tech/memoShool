<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('absences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('cours_id')->constrained('cours')->cascadeOnDelete();
            $table->foreignId('etudiant_id')->constrained('users')->cascadeOnDelete();
            $table->boolean('present')->default(false);
            $table->boolean('justifiee')->default(false);
            $table->enum('type_justification', ['permission', 'justificatif'])->nullable();
            $table->timestamp('date_justification')->nullable();
            $table->foreignId('justifie_par')->nullable()->constrained('users')->nullOnDelete();
            $table->text('observation')->nullable();
            $table->timestamps();

            // Un étudiant ne peut avoir qu'une seule entrée par cours
            $table->unique(['cours_id', 'etudiant_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('absences');
    }
};