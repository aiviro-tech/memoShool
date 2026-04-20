<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up() {
        Schema::create('membres_ecole', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('ecole_id')->constrained('ecoles')->onDelete('cascade');
            $table->enum('role', ['admin', 'enseignant', 'etudiant']);
            $table->enum('statut', ['en_attente', 'actif', 'rejete'])->default('en_attente');
            $table->string('code_utilise')->nullable();
            // Champs étudiant
            $table->string('niveau')->nullable();
            $table->string('matricule')->nullable();
            $table->string('annee_entree')->nullable();
            $table->string('statut_etudiant')->nullable();
            $table->string('tuteur_nom')->nullable();
            $table->string('tuteur_tel')->nullable();
            // Champs enseignant
            $table->string('matiere_principale')->nullable();
            $table->string('diplome')->nullable();
            $table->string('experience_annees')->nullable();
            $table->string('type_contrat')->nullable();
            // Champs admin
            $table->string('poste')->nullable();
            $table->string('service')->nullable();
            $table->string('niveau_acces')->nullable();
            $table->string('motif_rejet')->nullable();
            $table->timestamps();
        });
    }

    public function down() {
        Schema::dropIfExists('membres_ecole');
    }
};