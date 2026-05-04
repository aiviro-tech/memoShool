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
        // 1. Rename 'ecues' to 'ues'
        Schema::rename('ecues', 'ues');

        // 2. Rename 'matieres' to 'ecues'
        Schema::rename('matieres', 'ecues');

        // 3. Update columns in the new 'ecues' table (formerly 'matieres')
        Schema::table('ecues', function (Blueprint $table) {
            $table->renameColumn('ecue_id', 'ue_id');
        });

        // 4. Update columns in 'cours' table
        Schema::table('cours', function (Blueprint $table) {
            $table->renameColumn('matiere_id', 'ecue_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cours', function (Blueprint $table) {
            $table->renameColumn('ecue_id', 'matiere_id');
        });

        Schema::table('ecues', function (Blueprint $table) {
            $table->renameColumn('ue_id', 'ecue_id');
        });

        Schema::rename('ecues', 'matieres');
        Schema::rename('ues', 'ecues');
    }
};
