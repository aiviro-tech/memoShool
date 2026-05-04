<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Lister les notifications de l'utilisateur connecté.
     */
    public function index(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        $query = Notification::where('user_id', $user->id)
                             ->where('ecole_id', $ecole_id)
                             ->orderByDesc('created_at');

        // Filtrer par statut lu/non lu
        if ($request->filled('lu')) {
            $query->where('lu', $request->boolean('lu'));
        }

        // Filtrer par type
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        $notifications = $query->get();

        return response()->json([
            'success'      => true,
            'data'         => $notifications,
            'total'        => $notifications->count(),
            'non_lues'     => $notifications->where('lu', false)->count(),
        ]);
    }

    /**
     * Marquer une notification comme lue.
     */
    public function marquerLue(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user         = $request->user();
        $notification = Notification::where('user_id', $user->id)
                                    ->where('ecole_id', $ecole_id)
                                    ->findOrFail($id);

        $notification->marquerCommeLu();

        return response()->json([
            'success' => true,
            'message' => 'Notification marquée comme lue.',
            'data'    => $notification,
        ]);
    }

    /**
     * Marquer toutes les notifications comme lues.
     */
    public function marquerToutesLues(Request $request, int $ecole_id): JsonResponse
    {
        $user = $request->user();

        Notification::where('user_id', $user->id)
                    ->where('ecole_id', $ecole_id)
                    ->where('lu', false)
                    ->update([
                        'lu'    => true,
                        'lu_at' => now(),
                    ]);

        return response()->json([
            'success' => true,
            'message' => 'Toutes les notifications marquées comme lues.',
        ]);
    }

    /**
     * Supprimer une notification.
     */
    public function destroy(Request $request, int $ecole_id, int $id): JsonResponse
    {
        $user         = $request->user();
        $notification = Notification::where('user_id', $user->id)
                                    ->where('ecole_id', $ecole_id)
                                    ->findOrFail($id);

        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notification supprimée.',
        ]);
    }

    /**
     * Nombre de notifications non lues.
     */
    public function compteurNonLues(Request $request, int $ecole_id): JsonResponse
    {
        $count = Notification::where('user_id', $request->user()->id)
                             ->where('ecole_id', $ecole_id)
                             ->where('lu', false)
                             ->count();

        return response()->json([
            'success' => true,
            'count'   => $count,
        ]);
    }
}