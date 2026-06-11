<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ecoles', function (Blueprint $table) {
            $table->string('autorisation_fichier')->nullable()->after('description_complete');
            $table->string('registre_commerce_fichier')->nullable()->after('autorisation_fichier');
            $table->string('ifu_fichier')->nullable()->after('registre_commerce_fichier');
            $table->string('logo_fichier')->nullable()->after('ifu_fichier');
            $table->string('façade_fichier')->nullable()->after('logo_fichier');
            $table->string('piece_identite_fichier')->nullable()->after('façade_fichier');
            $table->string('cachet_fichier')->nullable()->after('piece_identite_fichier');
        });
    }

    public function down(): void
    {
        Schema::table('ecoles', function (Blueprint $table) {
            $table->dropColumn([
                'autorisation_fichier',
                'registre_commerce_fichier',
                'ifu_fichier',
                'logo_fichier',
                'façade_fichier',
                'piece_identite_fichier',
                'cachet_fichier'
            ]);
        });
    }
};