<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('ecoles', function (Blueprint $table) {
            if (!Schema::hasColumn('ecoles', 'logo')) {
                $table->string('logo')->nullable()->after('sigle');
            }
        });
    }

    public function down(): void {
        Schema::table('ecoles', function (Blueprint $table) {
            if (Schema::hasColumn('ecoles', 'logo')) {
                $table->dropColumn('logo');
            }
        });
    }
};
