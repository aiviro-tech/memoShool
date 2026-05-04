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
        Schema::table('membres_ecole', function (Blueprint $table) {
            $table->renameColumn('matiere_principale', 'ecue_principale');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('membres_ecole', function (Blueprint $table) {
            $table->renameColumn('ecue_principale', 'matiere_principale');
        });
    }
};
