<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up() {
        Schema::create('codes_invitation', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ecole_id')->constrained('ecoles')->onDelete('cascade');
            $table->string('code')->unique();
            $table->enum('role', ['admin', 'enseignant', 'etudiant']);
            $table->string('destinataire')->nullable();
            $table->boolean('utilise')->default(false);
            $table->foreignId('genere_par')->constrained('users');
            $table->timestamps();
        });
    }

    public function down() {
        Schema::dropIfExists('codes_invitation');
    }
};