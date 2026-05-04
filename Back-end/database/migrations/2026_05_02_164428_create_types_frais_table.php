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
        Schema::create('types_frais', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classe_id')
                  ->constrained('classes')
                  ->cascadeOnDelete();
            $table->string('libelle');
            $table->decimal('montant', 10, 2);
            $table->boolean('obligatoire')
                  ->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('types_frais');
    }
};
