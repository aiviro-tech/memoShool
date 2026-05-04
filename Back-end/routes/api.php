<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FiliereController;
use App\Http\Controllers\Api\ClasseController;
use App\Http\Controllers\Api\SalleController;
use App\Http\Controllers\Api\EcueController;
use App\Http\Controllers\Api\UeController;
use App\Http\Controllers\Api\CoursController;
use App\Http\Controllers\Api\SupportCoursController;
use App\Http\Controllers\Api\EcoleConfigController;
use App\Http\Controllers\Api\NoteController;
use App\Http\Controllers\Api\ReleveController;
use App\Http\Controllers\Api\AbsenceController;
use App\Http\Controllers\Api\TypeFraisController;
use App\Http\Controllers\Api\InscriptionController;
use App\Http\Controllers\Api\PaiementController;
use App\Http\Controllers\Api\AnnonceController;
use App\Http\Controllers\Api\NotificationController;

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


// Webhook FedaPay — sans authentification
Route::post('/paiements/webhook', [PaiementController::class, 'webhook']);


// Routes protégées
Route::middleware('auth:sanctum')->group(function () {
        
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

        // Membres de l'école (Enseignants, étudiants, etc)
        Route::get('/membres', [\App\Http\Controllers\Api\EcoleController::class, 'membres']);

        // Filières
        Route::get('/filieres', [FiliereController::class, 'index']);
        Route::post('/filieres', [FiliereController::class, 'store']);
        Route::put('/filieres/{id}', [FiliereController::class, 'update']);
        Route::delete('/filieres/{id}', [FiliereController::class, 'destroy']);

        // Semestres
        Route::prefix('semestres')->group(function () {
            Route::get('/', [App\Http\Controllers\Api\SemestreController::class, 'index']);
            Route::post('/', [App\Http\Controllers\Api\SemestreController::class, 'store']);
            Route::get('{id}', [App\Http\Controllers\Api\SemestreController::class, 'show']);
            Route::put('{id}', [App\Http\Controllers\Api\SemestreController::class, 'update']);
            Route::delete('{id}', [App\Http\Controllers\Api\SemestreController::class, 'destroy']);
        });

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

        // UE Routes
        Route::prefix('ues')->group(function () {
        Route::get('/', [App\Http\Controllers\Api\UeController::class, 'index']);
        Route::post('/', [App\Http\Controllers\Api\UeController::class, 'store']);
        Route::get('{id}', [App\Http\Controllers\Api\UeController::class, 'show']);
        Route::put('{id}', [App\Http\Controllers\Api\UeController::class, 'update']);
        Route::delete('{id}', [App\Http\Controllers\Api\UeController::class, 'destroy']);
        });

        // ECUE Routes
        Route::get('/ecues', [EcueController::class, 'index']);
        Route::post('/ecues', [EcueController::class, 'store']);
        Route::put('/ecues/{id}', [EcueController::class, 'update']);
        Route::delete('/ecues/{id}', [EcueController::class, 'destroy']);

        // Cours
        Route::get('/cours', [CoursController::class, 'index']);
        Route::post('/cours', [CoursController::class, 'store']);
        Route::get('/cours/emploi-du-temps', [CoursController::class, 'emploiDuTemps']);
        Route::get('/cours/{id}', [CoursController::class, 'show']);
        Route::put('/cours/{id}', [CoursController::class, 'update']);
        Route::delete('/cours/{id}', [CoursController::class, 'destroy']);
        Route::patch('/cours/{id}/statut', [CoursController::class, 'changerStatut']);

        // Supports de cours
        Route::get('/supports', [SupportCoursController::class, 'index']);
        Route::post('/supports', [SupportCoursController::class, 'store']);
        Route::put('/supports/{id}/valider', [SupportCoursController::class, 'valider']);
        Route::put('/supports/{id}/rejeter', [SupportCoursController::class, 'rejeter']);
        Route::get('/supports/{id}/download', [SupportCoursController::class, 'download']);
        Route::delete('/supports/{id}', [SupportCoursController::class, 'destroy']);
        Route::get('/supports/{id}', [SupportCoursController::class, 'show']);

        // Configuration de l'école
        Route::get('/config', [EcoleConfigController::class, 'show']);
        Route::post('/config', [EcoleConfigController::class, 'upsert']);

        // Types de frais par classe
        Route::get('/classes/{classe_id}/types-frais', [TypeFraisController::class, 'index']);
        Route::post('/classes/{classe_id}/types-frais', [TypeFraisController::class, 'store']);
        Route::put('/classes/{classe_id}/types-frais/{id}', [TypeFraisController::class, 'update']);
        Route::delete('/classes/{classe_id}/types-frais/{id}', [TypeFraisController::class, 'destroy']);

        // Échéances par classe
        Route::get('/classes/{classe_id}/echeances', [EcoleConfigController::class, 'showEcheances']);
        Route::post('/classes/{classe_id}/echeances', [EcoleConfigController::class, 'upsertEcheances']);

        // Notes & Devoirs
        Route::get('/devoirs', [NoteController::class, 'indexDevoirs']);
        Route::post('/devoirs', [NoteController::class, 'storeDevoir']);
        Route::post('/devoirs/{devoir_id}/notes', [NoteController::class, 'saisirNotes'])
            ->middleware('note.autorisation');
        Route::get('/notes/etudiant', [NoteController::class, 'notesEtudiant']);

        // Autorisations saisie notes
        Route::post('/notes/autoriser', [NoteController::class, 'autoriser']);
        Route::patch('/notes/autoriser/{id}/revoquer', [NoteController::class, 'revoquer']);

        // Relevés & Moyennes
        Route::get('/releves', [ReleveController::class, 'index']);
        Route::post('/releves/generer', [ReleveController::class, 'generer']);
        Route::get('/releves/{id}/telecharger', [ReleveController::class, 'telecharger']);
        Route::get('/releves/bilan-annuel', [ReleveController::class, 'bilanAnnuel']);
        Route::get('/releves/moyennes-semestre', [ReleveController::class, 'moyennesSemestre']);

        // Absences
        Route::post('/cours/{cours_id}/presences', [AbsenceController::class, 'saisirPresences']);
        Route::get('/cours/{cours_id}/presences', [AbsenceController::class, 'presencesCours']);
        Route::patch('/absences/{id}/justifier', [AbsenceController::class, 'justifier']);
        Route::get('/absences', [AbsenceController::class, 'index']);
        Route::get('/absences/statut-exclusion', [AbsenceController::class, 'statutExclusion']);

        // Inscriptions
        Route::get('/inscriptions', [InscriptionController::class, 'index']);
        Route::post('/inscriptions', [InscriptionController::class, 'store']);
        Route::get('/inscriptions/{id}', [InscriptionController::class, 'show']);
        Route::put('/inscriptions/{id}/valider', [InscriptionController::class, 'valider']);
        Route::put('/inscriptions/{id}/rejeter', [InscriptionController::class, 'rejeter']);

       // Paiements & Frais
        Route::get('/paiements/frais', [PaiementController::class, 'fraisEtudiant']);
        Route::post('/paiements/initier', [PaiementController::class, 'initierPaiement']);
        Route::get('/paiements/historique', [PaiementController::class, 'historique']);
        Route::get('/paiements/{id}/statut', [PaiementController::class, 'verifierStatut']);
        Route::post('/paiements/{id}/recu', [PaiementController::class, 'genererRecu']);
        Route::get('/paiements/{id}/recu', [PaiementController::class, 'telechargerRecu']);
        Route::post('/frais', [PaiementController::class, 'storeFrais']);

        Route::get('/paiements/fiche-frais', [PaiementController::class, 'ficheFrais']);


        // Dans le groupe ecoles/{ecole_id}
        Route::get('/annonces', [AnnonceController::class, 'index']);
        Route::post('/annonces', [AnnonceController::class, 'store']);
        Route::put('/annonces/{id}', [AnnonceController::class, 'update']);
        Route::delete('/annonces/{id}', [AnnonceController::class, 'destroy']);


        // Dans le groupe ecoles/{ecole_id}
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::get('/notifications/compteur', [NotificationController::class, 'compteurNonLues']);
        Route::patch('/notifications/{id}/lue', [NotificationController::class, 'marquerLue']);
        Route::patch('/notifications/toutes-lues', [NotificationController::class, 'marquerToutesLues']);
        Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    });

    // En dehors du groupe ecoles/{ecole_id} mais dans auth:sanctum
    Route::post('/fcm-token', [AnnonceController::class, 'enregistrerToken']);
});