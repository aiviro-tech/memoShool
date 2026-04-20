<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('membres_ecole', function (Blueprint $table) {
            // Ajouter les champs de validation manquants
            if (!Schema::hasColumn('membres_ecole', 'validated_by')) {
                $table->foreignId('validated_by')->nullable()->constrained('users')->onDelete('set null')->after('motif_rejet');
            }
            if (!Schema::hasColumn('membres_ecole', 'validated_at')) {
                $table->timestamp('validated_at')->nullable()->after('validated_by');
            }
            if (!Schema::hasColumn('membres_ecole', 'joined_at')) {
                $table->timestamp('joined_at')->nullable()->after('validated_at');
            }
        });
    }

    public function down(): void {
        Schema::table('membres_ecole', function (Blueprint $table) {
            if (Schema::hasColumn('membres_ecole', 'validated_by')) {
                $table->dropForeignKeyIfExists(['validated_by']);
                $table->dropColumn('validated_by');
            }
            if (Schema::hasColumn('membres_ecole', 'validated_at')) {
                $table->dropColumn('validated_at');
            }
            if (Schema::hasColumn('membres_ecole', 'joined_at')) {
                $table->dropColumn('joined_at');
            }
        });
    }
};
