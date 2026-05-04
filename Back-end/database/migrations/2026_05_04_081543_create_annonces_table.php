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
        Schema::create('annonces', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->cascadeOnDelete();
            $table->foreignId('publie_par')->constrained('users')->cascadeOnDelete();
            $table->string('titre');
            $table->text('contenu');
            $table->enum('cible', ['tous', 'etudiants', 'enseignants']);
            $table->enum('niveau_cible', ['L1', 'L2', 'L3', 'M1', 'M2'])->nullable();
            $table->foreignId('classe_cible')->nullable()->constrained('classes')->nullOnDelete();
            $table->timestamp('date_publication')->nullable();
            $table->boolean('publie')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('annonces');
    }
};
