<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('supports_cours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('cours_id')->constrained('cours')->cascadeOnDelete();
            $table->foreignId('enseignant_id')->constrained('users')->cascadeOnDelete();
            $table->string('titre');
            $table->text('description')->nullable();
            $table->string('fichier_path'); // chemin du fichier uploadé
            $table->string('fichier_nom');  // nom original du fichier
            $table->string('fichier_type'); // pdf, docx, pptx, etc.
            $table->unsignedBigInteger('fichier_taille')->default(0); // taille en bytes
            $table->enum('statut', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->text('motif_rejet')->nullable();
            $table->foreignId('valide_par')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('valide_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supports_cours');
    }
};
