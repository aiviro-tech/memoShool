<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CodeInvitation;
use App\Models\MembreEcole;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CodeInvitationController extends Controller {

    // Générer un code
    public function generer(Request $request) {
        $request->validate([
            'role'         => 'required|in:etudiant,enseignant,admin',
            'destinataire' => 'required|string',
        ]);

        $user = $request->user();

        // Vérifier que l'user est admin d'une école
        $membre = MembreEcole::where('user_id', $user->id)
            ->where('role', 'admin')
            ->where('statut', 'actif')
            ->first();

        if (!$membre) {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        // Générer un code unique
        $prefixe = $request->role == 'etudiant'
            ? 'ETU-'
            : ($request->role == 'enseignant' ? 'ENS-' : 'ADM-');
        do {
            $code = $prefixe . strtoupper(Str::random(8));
        } while (CodeInvitation::where('code', $code)->exists());

        $codeInvitation = CodeInvitation::create([
            'ecole_id'    => $membre->ecole_id,
            'code'        => $code,
            'role'        => $request->role,
            'destinataire'=> $request->destinataire,
            'utilise'     => false,
            'genere_par'  => $user->id,
        ]);

        return response()->json([
            'message' => 'Code généré avec succès.',
            'code'    => $codeInvitation,
        ], 201);
    }

    // Vérifier un code sans le marquer utilisé
    public function verifier(Request $request) {
        $request->validate(['code' => 'required|string']);

        $code = strtoupper($request->code);
        $codeInvitation = CodeInvitation::with('ecole')
            ->where('code', $code)
            ->where('utilise', false)
            ->first();

        if (!$codeInvitation) {
            return response()->json([
                'valide'  => false,
                'message' => 'Code invalide ou déjà utilisé.',
            ], 422);
        }

        return response()->json([
            'valide'  => true,
            'role'    => $codeInvitation->role,
            'ecole'   => $codeInvitation->ecole->nom_officiel,
            'ecole_id'=> $codeInvitation->ecole_id,
        ]);
    }

    // Mes codes générés
    public function mesCodes(Request $request) {
        $user = $request->user();

        $membre = MembreEcole::where('user_id', $user->id)
            ->where('role', 'admin')
            ->where('statut', 'actif')
            ->first();

        if (!$membre) {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $codes = CodeInvitation::where('ecole_id', $membre->ecole_id)
            ->whereIn('role', ['etudiant', 'enseignant', 'admin'])
            ->latest()
            ->get();

        return response()->json($codes);
    }

    // Régénérer un code (marquer ancien inactif, générer nouveau)
    public function regenerer(Request $request, $codeId) {
        $user = $request->user();

        // Récupérer le code à régénérer
        $oldCode = CodeInvitation::findOrFail($codeId);

        // Vérifier que l'user est admin de cette école
        $membre = MembreEcole::where('user_id', $user->id)
            ->where('ecole_id', $oldCode->ecole_id)
            ->where('role', 'admin')
            ->where('statut', 'actif')
            ->first();

        if (!$membre) {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        // Marquer l'ancien code comme inactif
        $oldCode->update(['is_active' => false]);

        // Générer un nouveau code avec le même rôle
        $prefix = $oldCode->role === 'etudiant'
            ? 'ETU-'
            : ($oldCode->role === 'enseignant' ? 'ENS-' : 'ADM-');

        do {
            $newCode = $prefix . strtoupper(Str::random(8));
        } while (CodeInvitation::where('code', $newCode)->exists());

        // Créer le nouveau code
        $codeInvitation = CodeInvitation::create([
            'ecole_id'     => $oldCode->ecole_id,
            'code'         => $newCode,
            'role'         => $oldCode->role,
            'destinataire' => null,
            'utilise'      => false,
            'genere_par'   => $user->id,
            'is_active'    => true,
        ]);

        return response()->json([
            'message'   => 'Code régénéré avec succès.',
            'ancien'   => $oldCode->code,
            'nouveau'  => $codeInvitation->code,
            'code'     => $codeInvitation,
        ], 201);
    }
}