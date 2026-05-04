<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('ecues', function (Blueprint $table) {
            $table->id();
            
            $table->foreignId('semestre_id')
                  ->constrained('semestres')
                  ->onDelete('cascade');

            $table->string('code')->unique();           // Exemple : INFO-S1-UE1
            $table->string('libelle');                  // Exemple : Programmation Mobile
            $table->integer('credits_ects')->default(0);
            $table->text('description')->nullable();

            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('ecues');
    }
};