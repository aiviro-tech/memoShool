<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('inscription_id')->constrained('inscriptions')->cascadeOnDelete();
            $table->foreignId('etudiant_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('montant', 10, 2);
            $table->string('currency')->default('XOF');
            $table->enum('mode_paiement', ['mtn_money', 'moov_money'])->nullable();
            $table->string('fedapay_transaction_id')->nullable()->unique();
            $table->string('fedapay_token')->nullable();
            $table->string('reference_paiement')->nullable();
            $table->string('numero_recu')->nullable()->unique();
            $table->enum('statut', ['pending', 'approved', 'declined', 'canceled'])->default('pending');
            $table->string('recu')->nullable();
            $table->timestamp('date_paiement')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};