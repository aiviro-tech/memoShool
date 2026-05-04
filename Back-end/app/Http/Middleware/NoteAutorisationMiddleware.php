<?php

namespace App\Http\Middleware;

use App\Models\AutorisationSaisieNote;
use Closure;
use Illuminate\Http\Request;

class NoteAutorisationMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        // Si c'est un admin, il passe toujours
        if ($user->isAdmin()) {
            return $next($request);
        }

        // Si c'est un enseignant, on vérifie l'autorisation
        if ($user->isEnseignant()) {
            $semestre_id = $request->route('semestre_id') 
                        ?? $request->input('semestre_id');

            if (!$semestre_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Le semestre est requis pour la saisie de notes.',
                ], 422);
            }

            $ecole_id = $request->route('ecole_id');

            $autorisation = AutorisationSaisieNote::where('enseignant_id', $user->id)
                ->where('ecole_id', $ecole_id)
                ->where('semestre_id', $semestre_id)
                ->first();

            if (!$autorisation || !$autorisation->estActive()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à saisir des notes pour ce semestre. Contactez l\'administration.',
                ], 403);
            }

            return $next($request);
        }

        // Autres rôles refusés
        return response()->json([
            'success' => false,
            'message' => 'Accès refusé.',
        ], 403);
    }
}