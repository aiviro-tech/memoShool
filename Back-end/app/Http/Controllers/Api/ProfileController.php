<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    // ── 1. Récupérer le profil ────────────────────────────────────────────────
    public function getProfile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'user' => [
                'id'           => $user->id,
                'first_name'   => $user->first_name,
                'last_name'    => $user->last_name,
                'full_name'    => $user->first_name . ' ' . $user->last_name,
                'email'        => $user->email,
                'phone'        => $user->phone,
                'role'         => $user->role,
                'photo_profil' => $user->photo_profil
                    ? asset('storage/' . $user->photo_profil)
                    : null,
            ]
        ]);
    }

    // ── 2. Modifier nom, prénom, téléphone ────────────────────────────────────
    public function updateInfo(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name'  => 'required|string|max:255',
            'phone'      => 'nullable|string|max:20',
        ]);

        $user = $request->user();
        $user->update($validated);

        return response()->json([
            'message' => 'Profil mis à jour avec succès.',
            'user'    => [
                'id'           => $user->id,
                'first_name'   => $user->first_name,
                'last_name'    => $user->last_name,
                'full_name'    => $user->first_name . ' ' . $user->last_name,
                'email'        => $user->email,
                'phone'        => $user->phone,
                'role'         => $user->role,
                'photo_profil' => $user->photo_profil
                    ? asset('storage/' . $user->photo_profil)
                    : null,
            ]
        ]);
    }

    // ── 3. Upload photo de profil ─────────────────────────────────────────────
    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048',
        ]);

        $user = $request->user();

        // Supprimer l'ancienne photo si elle existe
        if ($user->photo_profil) {
            Storage::disk('public')->delete($user->photo_profil);
        }

        // Stocker la nouvelle photo dans storage/app/public/photos/
        $path = $request->file('photo')->store('photos', 'public');

        $user->update(['photo_profil' => $path]);

        return response()->json([
            'message'      => 'Photo de profil mise à jour avec succès.',
            'photo_profil' => asset('storage/' . $path),
        ]);
    }

    // ── 4. Supprimer la photo de profil ───────────────────────────────────────
    public function deletePhoto(Request $request)
    {
        $user = $request->user();

        if (!$user->photo_profil) {
            return response()->json([
                'message' => 'Aucune photo de profil à supprimer.',
            ], 404);
        }

        // Supprimer le fichier du disque
        Storage::disk('public')->delete($user->photo_profil);

        // Mettre à null dans la base de données
        $user->update(['photo_profil' => null]);

        return response()->json([
            'message'      => 'Photo de profil supprimée avec succès.',
            'photo_profil' => null,
        ]);
    }

    // ── 5. Modifier mot de passe ──────────────────────────────────────────────
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password'         => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        // Vérifier que l'ancien mot de passe est correct
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Le mot de passe actuel est incorrect.',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'Mot de passe modifié avec succès.',
        ]);
    }
}