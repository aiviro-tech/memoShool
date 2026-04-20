<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // Ajouter la colonne is_active pour gérer la régénération des codes
        Schema::table('codes_invitation', function (Blueprint $table) {
            if (!Schema::hasColumn('codes_invitation', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('utilise');
            }
        });
    }

    public function down(): void {
        Schema::table('codes_invitation', function (Blueprint $table) {
            if (Schema::hasColumn('codes_invitation', 'is_active')) {
                $table->dropColumn('is_active');
            }
        });
    }
};
