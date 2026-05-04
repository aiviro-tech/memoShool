<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Releve;
use App\Services\MoyenneCalculatorService;
use App\Services\ReleveGeneratorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReleveController extends Controller
{
    /**
     * Générer ou régénérer le relevé d'un étudiant pour un semestre.
     * Admin ou étudiant concerné uniquement.
     */
    public function generer(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'etudiant_id' => 'required|exists:users,id',
            'semestre_id' => 'required|exists:semestres,id',
            'classe_id'   => 'required|exists:classes,id',
            'session'     => 'required|integer|in:1,2',
        ]);

        // Un étudiant ne peut générer que son propre relevé
        if ($user->isEtudiant() && $user->id !== $validated['etudiant_id']) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez générer que votre propre relevé.',
            ], 403);
        }

        try {
            $service  = new ReleveGeneratorService($ecole_id);
            $resultat = $service->generer(
                $validated['etudiant_id'],
                $validated['semestre_id'],
                $validated['classe_id'],
                $validated['session']
            );

            return response()->json([
                'success' => true,
                'message' => 'Relevé généré avec succès.',
                'data'    => $resultat['releve'],
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération du relevé : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Télécharger le PDF du relevé.
     */
    public function telecharger(Request $request, int $ecole_id, int $id)
    {
        $user   = $request->user();
        $releve = Releve::where('ecole_id', $ecole_id)->findOrFail($id);

        // Un étudiant ne peut télécharger que son propre relevé
        if ($user->isEtudiant() && $user->id !== $releve->etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez télécharger que votre propre relevé.',
            ], 403);
        }

        if (!$releve->fichier_path || !Storage::disk('public')->exists($releve->fichier_path)) {
            return response()->json([
                'success' => false,
                'message' => 'Le fichier PDF n\'existe pas. Veuillez régénérer le relevé.',
            ], 404);
        }

        return Storage::disk('public')->download(
            $releve->fichier_path,
            "releve_{$releve->etudiant_id}_s{$releve->semestre_id}_session{$releve->session}.pdf"
        );
    }

    /**
     * Consulter les relevés d'un étudiant.
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $etudiant_id = $user->isEtudiant()
            ? $user->id
            : $request->input('etudiant_id');

        if (!$etudiant_id) {
            return response()->json([
                'success' => false,
                'message' => 'etudiant_id est requis.',
            ], 422);
        }

        $releves = Releve::with(['semestre', 'classe.filiere'])
            ->where('ecole_id', $ecole_id)
            ->where('etudiant_id', $etudiant_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $releves,
        ]);
    }

    /**
     * Consulter le bilan annuel d'un étudiant.
     */
    public function bilanAnnuel(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'etudiant_id'  => 'required|exists:users,id',
            'classe_id'    => 'required|exists:classes,id',
            'semestre_ids' => 'required|array|min:2|max:2',
            'semestre_ids.*' => 'required|exists:semestres,id',
        ]);

        // Un étudiant ne peut voir que son propre bilan
        if ($user->isEtudiant() && $user->id !== $validated['etudiant_id']) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez consulter que votre propre bilan.',
            ], 403);
        }

        try {
            $service = new MoyenneCalculatorService($ecole_id);
            $bilan   = $service->calculerBilanAnnuel(
                $validated['etudiant_id'],
                $validated['classe_id'],
                $validated['semestre_ids']
            );

            return response()->json([
                'success' => true,
                'data'    => $bilan,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul du bilan : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Consulter les moyennes d'un étudiant pour un semestre.
     */
    public function moyennesSemestre(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'etudiant_id' => 'required|exists:users,id',
            'semestre_id' => 'required|exists:semestres,id',
            'classe_id'   => 'required|exists:classes,id',
            'session'     => 'sometimes|integer|in:1,2',
        ]);

        // Un étudiant ne peut voir que ses propres moyennes
        if ($user->isEtudiant() && $user->id !== $validated['etudiant_id']) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez consulter que vos propres moyennes.',
            ], 403);
        }

        try {
            $service  = new MoyenneCalculatorService($ecole_id);
            $session  = $validated['session'] ?? 1;
            $resultat = $service->calculerMoyenneSemestre(
                $validated['etudiant_id'],
                $validated['semestre_id'],
                $validated['classe_id'],
                $session
            );

            return response()->json([
                'success' => true,
                'data'    => $resultat,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul des moyennes : ' . $e->getMessage(),
            ], 500);
        }
    }
}