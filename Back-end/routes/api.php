<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FiliereController;
use App\Http\Controllers\Api\ClasseController;
use App\Http\Controllers\Api\SalleController;
use App\Http\Controllers\Api\MatiereController;
use App\Http\Controllers\Api\CoursController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
});

Route::post('/verify-email', [AuthController::class, 'verifyEmail']);

Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

Route::post('/resend-verification-code', [AuthController::class, 'resendVerificationCode']);
Route::post('/resend-reset-code', [AuthController::class, 'resendResetCode']);
use App\Http\Controllers\Api\EcoleController;
use App\Http\Controllers\Api\CodeInvitationController;

// Routes protégées
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Écoles
    Route::post('/ecoles', [EcoleController::class, 'store']);
    Route::get('/ecoles/en-attente', [EcoleController::class, 'enAttente']);
    Route::get('/ecoles/traitees', [EcoleController::class, 'ecolesTraitees']);
    Route::put('/ecoles/{id}/activer', [EcoleController::class, 'activer']);
    Route::put('/ecoles/{id}/refuser', [EcoleController::class, 'refuser']);
    Route::delete('/ecoles/{id}', [EcoleController::class, 'supprimer']);
    Route::get('/mes-ecoles', [EcoleController::class, 'mesEcoles']);
    Route::get('/dashboard', [EcoleController::class, 'dashboardAccueil']); // Page d'accueil après connexion

    // Codes d'invitation
    Route::post('/codes/generer', [CodeInvitationController::class, 'generer']);
    Route::post('/codes/verifier', [CodeInvitationController::class, 'verifier']);
    Route::get('/mes-codes', [CodeInvitationController::class, 'mesCodes']);
    Route::put('/codes/{codeId}/regenerer', [CodeInvitationController::class, 'regenerer']);

    // Membres
    Route::post('/rejoindre', [EcoleController::class, 'rejoindre']);
    Route::get('/demandes-en-attente', [EcoleController::class, 'demandesEnAttente']);
    Route::put('/demandes/{id}/accepter', [EcoleController::class, 'accepterDemande']);
    Route::put('/demandes/{id}/rejeter', [EcoleController::class, 'rejeterDemande']);

   // ── Routes par école ────────────────────────────────────
    Route::prefix('ecoles/{ecole_id}')->group(function () {

        // Filières
        Route::get('/filieres', [FiliereController::class, 'index']);
        Route::post('/filieres', [FiliereController::class, 'store']);
        Route::put('/filieres/{id}', [FiliereController::class, 'update']);
        Route::delete('/filieres/{id}', [FiliereController::class, 'destroy']);

        // Classes
        Route::get('/classes', [ClasseController::class, 'index']);
        Route::post('/classes', [ClasseController::class, 'store']);
        Route::put('/classes/{id}', [ClasseController::class, 'update']);
        Route::get('/classes/{id}/etudiants', [ClasseController::class, 'etudiants']);

        // Salles
        Route::get('/salles', [SalleController::class, 'index']);
        Route::post('/salles', [SalleController::class, 'store']);
        Route::get('/salles/disponibles', [SalleController::class, 'disponibles']);
        Route::put('/salles/{id}', [SalleController::class, 'update']);

        // Matières
        Route::get('/matieres', [MatiereController::class, 'index']);
        Route::post('/matieres', [MatiereController::class, 'store']);
        Route::put('/matieres/{id}', [MatiereController::class, 'update']);
        Route::delete('/matieres/{id}', [MatiereController::class, 'destroy']);

        // Cours
        Route::get('/cours', [CoursController::class, 'index']);
        Route::post('/cours', [CoursController::class, 'store']);
        Route::get('/cours/emploi-du-temps', [CoursController::class, 'emploiDuTemps']);
        Route::get('/cours/{id}', [CoursController::class, 'show']);
        Route::put('/cours/{id}', [CoursController::class, 'update']);
        Route::delete('/cours/{id}', [CoursController::class, 'destroy']);
        Route::patch('/cours/{id}/statut', [CoursController::class, 'changerStatut']);
    });
});