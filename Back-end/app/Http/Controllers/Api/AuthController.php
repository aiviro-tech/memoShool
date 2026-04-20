<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\EmailOtp;                  // ← pour le modèle EmailOtp
use Illuminate\Support\Facades\Mail;      // ← pour la facade Mail
use App\Mail\PasswordResetOtpMail; // On va créer ce mail après
use Illuminate\Support\Str;


class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'first_name'     => 'required|string|max:255',
            'last_name'      => 'required|string|max:255',
            'email'          => 'required|string|email|max:255|unique:users',
            'password'       => 'required|string|min:8|confirmed',
            'date_of_birth'  => 'nullable|date_format:d/m/Y',
            'gender'         => 'nullable|in:M,F,other',
            'nationality'    => 'nullable|string|max:255',
            'phone'          => 'nullable|string|max:20',
        ]);

        // Créer l'utilisateur mais sans email vérifié
        $user = User::create([
            'first_name'     => $validated['first_name'],
            'last_name'      => $validated['last_name'],
            'email'          => $validated['email'],
            'password'       => Hash::make($request->password),
            'date_of_birth'  => $validated['date_of_birth'] ?? null,
            'gender'         => $validated['gender'] ?? null,
            'nationality'    => $validated['nationality'] ?? null,
            'phone'          => $validated['phone'] ?? null,
            'email_verified_at' => null,  // Pas encore vérifié
        ]);

        // Générer un code OTP à 6 chiffres (aléatoire)
        $otpCode = rand(100000, 999999);  // 6 chiffres entre 100000 et 999999

        // Enregistrer l'OTP dans la table
        $otp = EmailOtp::create([
            'user_id'     => $user->id,
            'code'        => $otpCode,
            'expires_at'  => now()->addMinutes(30),  // ← 30 minutes d'expiration
            'is_used'     => false,
        ]);

       // Après avoir créé l'utilisateur et l'OTP
        Mail::to($user->email)->send(new \App\Mail\EmailVerificationOtpMail($otpCode));
        
        // Réponse à l'utilisateur (pas de token pour l'instant)
        return response()->json([
            'message' => 'Inscription réussie ! Vérifiez votre email pour activer votre compte.',
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'last_name' => $user->last_name,
                'full_name' => $user->first_name . ' ' . $user->last_name, // optionnel, pratique pour l’affichage
                'email' => $user->email,
                'email_verified_at' => $user->email_verified_at,
            ],
            // Pas de token ici
        ], 201);
    }

   public function login(Request $request)
{
    $validated = $request->validate([
        'email'    => 'required|email',
        'password' => 'required|string|min:8',
    ]);

    $user = User::where('email', $validated['email'])->first();

    if (!$user || !Hash::check($validated['password'], $user->password)) {
        throw ValidationException::withMessages([
            'email' => ['Les identifiants sont incorrects.'],
        ]);
    }

    // Le super admin n'a pas besoin de vérifier son email
    if ($user->role !== 'super_admin' && !$user->hasVerifiedEmail()) {
        throw ValidationException::withMessages([
            'email' => ['Veuillez vérifier votre email avant de vous connecter.'],
        ]);
    }

    $token = $user->createToken('flutter-app')->plainTextToken;

    return response()->json([
        'message' => 'Connexion réussie',
        'user' => [
            'id'                => $user->id,
            'first_name'        => $user->first_name,
            'last_name'         => $user->last_name,
            'full_name'         => $user->first_name . ' ' . $user->last_name,
            'email'             => $user->email,
            'role'              => $user->role,
            'email_verified_at' => $user->email_verified_at,
        ],
        'token' => $token
    ]);
}

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnexion réussie']);
    }

    public function verifyEmail(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            'code'  => 'required|string|size:6',
        ]);

        $user = User::where('email', $request->email)->first();

        // Cherche le dernier OTP non utilisé pour cet utilisateur
        $otp = $user->emailOtps()
                    ->where('code', $request->code)
                    ->where('is_used', false)
                    ->where('expires_at', '>', now())
                    ->latest()
                    ->first();

        if (!$otp) {
            return response()->json([
                'message' => 'Code OTP invalide, expiré ou déjà utilisé.',
            ], 422);
        }

        // Marquer le code comme utilisé
       

        $otp->update(['is_used' => true]);

        // Update direct en base
        User::where('id', $user->id)->update([
            'email_verified_at' => now()
        ]);

        $user = $user->fresh();
        
        // Générer un token maintenant que c'est vérifié
        $token = $user->createToken('flutter-app')->plainTextToken;

        return response()->json([
            'message' => 'Email vérifié avec succès ! Vous pouvez maintenant vous connecter.',
            'user'    => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'last_name' => $user->last_name,
                'full_name' => $user->first_name . ' ' . $user->last_name, // optionnel, pratique pour l’affichage
                'email' => $user->email,
                'email_verified_at' => $user->email_verified_at,
            ],
            'token'   => $token,
        ]);
    }

    /**
     * Redemander un nouveau code de vérification d'email
     */
    public function resendVerificationCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $user = User::where('email', $request->email)->first();

        // Si l'email est déjà vérifié, pas besoin de renvoyer
        if ($user->hasVerifiedEmail()) {
            return response()->json([
                'message' => 'Votre email est déjà vérifié.',
            ], 400);
        }

        // Invalider tous les anciens OTP de vérification
        $user->emailOtps()
            ->where('is_used', false)
            ->update(['is_used' => true]);

        // Générer un nouveau code
        $code = rand(100000, 999999);

        $user->emailOtps()->create([
            'code' => $code,
            'expires_at' => now()->addMinutes(30),
        ]);

        // Envoyer l'email
        Mail::to($user->email)->send(new \App\Mail\EmailVerificationOtpMail($code));

        return response()->json([
            'message' => 'Un nouveau code de vérification a été envoyé à votre email.',
        ]);
    }

    // Mot de passe oublié : envoi du code OTP
    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            // Pas d'autres champs autorisés
        ]);


        $user = User::where('email', $request->email)->first();

        // Invalider TOUS les OTP précédents pour cet utilisateur
        $user->passwordResetOtps()
            ->where('is_used', false)
            ->update(['is_used' => true]);

        // Génère un code OTP 6 chiffres
        $code = rand(100000, 999999);

        // Crée l'OTP
        $user->passwordResetOtps()->create([
            'code' => $code,
            'expires_at' => now()->addMinutes(30),
        ]);

        // Envoie l'email (on crée la classe Mail ensuite)
        Mail::to($user->email)->send(new PasswordResetOtpMail($code));

        return response()->json([
            'message' => 'Un code de réinitialisation a été envoyé à votre email.',
        ]);
    }

    // Réinitialiser le mot de passe avec le code OTP
    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::where('email', $request->email)->first();

        $otp = $user->passwordResetOtps()
                    ->where('code', $request->code)
                    ->where('is_used', false)
                    ->where('expires_at', '>', now())
                    ->latest()
                    ->first();

        if (!$otp) {
            return response()->json([
                'message' => 'Code OTP invalide, expiré ou déjà utilisé.',
            ], 422);
        }

        // Marquer OTP comme utilisé
        $otp->update(['is_used' => true]);

        // Mettre à jour le mot de passe
        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'Mot de passe réinitialisé avec succès. Vous pouvez vous connecter.',
        ]);
    }

    /**
     * Redemander un nouveau code pour réinitialiser le mot de passe
     */
    public function resendResetCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $user = User::where('email', $request->email)->first();

        // Invalider tous les anciens OTP de reset
        $user->passwordResetOtps()
            ->where('is_used', false)
            ->update(['is_used' => true]);

        // Générer un nouveau code
        $code = rand(100000, 999999);

        $user->passwordResetOtps()->create([
            'code' => $code,
            'expires_at' => now()->addMinutes(30),
        ]);

        // Envoyer l'email
        Mail::to($user->email)->send(new PasswordResetOtpMail($code));

        return response()->json([
            'message' => 'Un nouveau code de réinitialisation a été envoyé à votre email.',
        ]);
    }
}

