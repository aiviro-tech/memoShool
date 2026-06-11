<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();
        
        if ($driver === 'sqlite') {
            Schema::table('ecoles', function (Blueprint $table) {
                $table->string('statut_temp')->default('en_attente');
            });
            
            DB::statement("UPDATE ecoles SET statut_temp = statut");
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->dropColumn('statut');
            });
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->enum('statut', ['en_attente', 'active', 'refuse', 'desactivee'])->default('en_attente');
            });
            
            DB::statement("UPDATE ecoles SET statut = statut_temp");
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->dropColumn('statut_temp');
            });
        } else {
            DB::statement("ALTER TABLE ecoles MODIFY COLUMN statut ENUM('en_attente', 'active', 'refuse', 'desactivee') NOT NULL DEFAULT 'en_attente'");
        }
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();
        
        if ($driver === 'sqlite') {
            Schema::table('ecoles', function (Blueprint $table) {
                $table->string('statut_temp')->default('en_attente');
            });
            
            DB::statement("UPDATE ecoles SET statut_temp = statut");
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->dropColumn('statut');
            });
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->enum('statut', ['en_attente', 'active', 'refuse'])->default('en_attente');
            });
            
            DB::statement("UPDATE ecoles SET statut = statut_temp");
            
            Schema::table('ecoles', function (Blueprint $table) {
                $table->dropColumn('statut_temp');
            });
        } else {
            DB::statement("ALTER TABLE ecoles MODIFY COLUMN statut ENUM('en_attente', 'active', 'refuse') NOT NULL DEFAULT 'en_attente'");
        }
    }
};