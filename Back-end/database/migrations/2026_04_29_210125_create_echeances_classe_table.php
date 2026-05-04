<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('echeances_classe', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classe_id')->constrained('classes')->cascadeOnDelete();
            $table->unsignedTinyInteger('numero');        // 1ère, 2ème, 3ème échéance...
            $table->decimal('montant', 10, 2);            // montant en FCFA
            $table->date('date_limite');                  // date limite de paiement
            $table->string('libelle')->nullable();        // ex: "1ère tranche", "2ème tranche"
            $table->timestamps();

            // Une classe ne peut pas avoir deux échéances avec le même numéro
            $table->unique(['classe_id', 'numero']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('echeances_classe');
    }
};