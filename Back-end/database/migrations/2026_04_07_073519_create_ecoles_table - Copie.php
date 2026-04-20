<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up() {
        Schema::create('ecoles', function (Blueprint $table) {
            $table->id();
            $table->string('nom_officiel');
            $table->string('sigle')->nullable();
            $table->string('site_web')->nullable();
            $table->string('adresse');
            $table->string('ville');
            $table->string('code_postal')->nullable();
            $table->string('pays');
            $table->string('email_principal');
            $table->string('email_secondaire')->nullable();
            $table->string('tel_fixe');
            $table->string('tel_mobile')->nullable();
            $table->string('nom_responsable');
            $table->string('titre_responsable');
            $table->string('numero_rne')->nullable();
            $table->string('type_etablissement');
            $table->text('description_courte')->nullable();
            $table->text('description_complete')->nullable();
            $table->integer('max_etudiants')->nullable();
            $table->integer('max_enseignants')->nullable();
            $table->enum('statut', ['en_attente', 'active', 'refuse'])->default('en_attente');
            $table->foreignId('admin_id')->constrained('users');
            $table->string('motif_refus')->nullable();
            $table->timestamps();
        });
    }

    public function down() {
        Schema::dropIfExists('ecoles');
    }
};