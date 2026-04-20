<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

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
});