<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ecole;
use App\Models\CodeInvitation;
use App\Models\MembreEcole;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Mail\SchoolActivatedMail;
use Illuminate\Support\Facades\Mail;

class EcoleController extends Controller {

    // Créer une école
    public function store(Request $request) {
        $validated = $request->validate([
            'nom_officiel'      => 'required|string',
            'adresse'           => 'required|string',
            'ville'             => 'required|string',
            'pays'              => 'required|string',
            'email_principal'   => 'required|email',
            'tel_fixe'          => 'required|string',
            'nom_responsable'   => 'required|string',
            'titre_responsable' => 'required|string',
            'type_etablissement'=> 'required|string',
        ]);

        $ecole = Ecole::create([
            ...$validated,
            'sigle'               => $request->sigle,
            'site_web'            => $request->site_web,
            'code_postal'         => $request->code_postal,
            'email_secondaire'    => $request->email_secondaire,
            'tel_mobile'          => $request->tel_mobile,
            'numero_rne'          => $request->numero_rne,
            'description_courte'  => $request->description_courte,
            'description_complete'=> $request->description_complete,
            'max_etudiants'       => $request->max_etudiants,
            'max_enseignants'     => $request->max_enseignants,
            'admin_id'            => $request->user()->id,
            'statut'              => 'en_attente',
        ]);

        return response()->json([
            'message' => 'Demande de création soumise. En attente de validation.',
            'ecole'   => $ecole,
        ], 201);
    }

    // Super Admin — liste des écoles en attente
    public function enAttente(Request $request) {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $ecoles = Ecole::with('admin')
            ->where('statut', 'en_attente')
            ->latest()
            ->get();

        return response()->json($ecoles);
    }

    // Super Admin — activer une école
    public function activer(Request $request, $id) {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $ecole = Ecole::findOrFail($id);
        $ecole->update(['statut' => 'active']);

        // Ajouter automatiquement le créateur comme admin actif de l'école
        MembreEcole::firstOrCreate(
            [
                'user_id' => $ecole->admin_id,
                'ecole_id' => $ecole->id,
            ],
            [
                'role' => 'admin',
                'statut' => 'actif',
                'validated_by' => $request->user()->id, // Super-admin qui approuve
                'validated_at' => now(),
                'joined_at' => now(),
            ]
        );

        // Générer automatiquement les 3 codes d'invitation standard (cahier des charges §3.5)
        $roles = ['etudiant', 'enseignant', 'admin'];
        foreach ($roles as $role) {
            // Vérifier si le code existe déjà
            $existingCode = CodeInvitation::where('ecole_id', $ecole->id)
                ->where('role', $role)
                ->first();

            if (!$existingCode) {
                // Générer un code unique pour ce rôle
                $code = $this->generateUniqueCode($role);
                CodeInvitation::create([
                    'ecole_id'    => $ecole->id,
                    'code'        => $code,
                    'role'        => $role,
                    'destinataire'=> $ecole->admin->full_name ?? $ecole->nom_responsable,
                    'utilise'     => false,
                    'is_active'   => true,
                    'genere_par'  => $request->user()->id,
                ]);
            }
        }

        // Envoyer l'email avec les codes générés
        $codes = CodeInvitation::where('ecole_id', $ecole->id)
            ->where('is_active', true)
            ->get()
            ->keyBy('role');

        $emailDestinataire = $ecole->admin ? $ecole->admin->email : $ecole->email_principal;
        Mail::to($emailDestinataire)->send(new SchoolActivatedMail($ecole, $codes));

        return response()->json([
            'message'    => 'École activée avec succès. 3 codes d\'invitation ont été générés.',
            'codes'      => $codes,
            'ecole'      => $ecole,
        ]);
    }

    // Générer un code unique avec le préfixe approprié
    private function generateUniqueCode($role) {
        $prefixe = match($role) {
            'etudiant' => 'ETU-',
            'enseignant' => 'ENS-',
            'admin' => 'ADM-',
            default => 'CODE-'
        };

        do {
            $code = $prefixe . strtoupper(Str::random(8));
        } while (CodeInvitation::where('code', $code)->exists());

        return $code;
    }

    // Super Admin — refuser une école
    public function refuser(Request $request, $id) {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $ecole = Ecole::findOrFail($id);
        $ecole->update([
            'statut'       => 'refuse',
            'motif_refus'  => $request->motif ?? 'Dossier incomplet',
        ]);

        return response()->json(['message' => 'École refusée.', 'ecole' => $ecole]);
    }

    // Dashboard d'accueil : liste des écoles et demandes (cahier §3.6)
    public function dashboardAccueil(Request $request) {
        $user = $request->user();

        // Écoles actives de l'utilisateur (avec rôle et dernière connexion)
        $ecolesActives = MembreEcole::with('ecole')
            ->where('user_id', $user->id)
            ->where('statut', 'actif')
            ->latest('updated_at')
            ->get()
            ->map(fn($m) => [
                'id' => $m->id,
                'ecole_id' => $m->ecole_id,
                'nom' => $m->ecole->nom_officiel,
                'ville' => $m->ecole->ville,
                'pays' => $m->ecole->pays,
                'logo' => $m->ecole->logo,
                'role' => $m->role,
                'statut' => $m->statut,
                'joined_at' => $m->joined_at,
                'premiere_connexion' => $m->joined_at,
            ]);

        // Demandes en attente
        $demandesAttente = MembreEcole::with('ecole')
            ->where('user_id', $user->id)
            ->where('statut', 'en_attente')
            ->get()
            ->map(fn($m) => [
                'id' => $m->id,
                'ecole_id' => $m->ecole_id,
                'nom' => $m->ecole->nom_officiel,
                'role' => $m->role,
                'statut' => $m->statut,
                'date_demande' => $m->created_at,
            ]);

        // Demandes rejetées
        $demandesRejetees = MembreEcole::with('ecole')
            ->where('user_id', $user->id)
            ->where('statut', 'rejete')
            ->get()
            ->map(fn($m) => [
                'id' => $m->id,
                'ecole_id' => $m->ecole_id,
                'nom' => $m->ecole->nom_officiel,
                'role' => $m->role,
                'statut' => $m->statut,
                'motif_rejet' => $m->motif_rejet,
                'date_rejet' => $m->validated_at,
            ]);

        return response()->json([
            'message' => 'Bienvenue',
            'user' => [
                'nom_complet' => $user->full_name,
                'email' => $user->email,
                'role' => $user->role,
            ],
            'ecoles_actives' => $ecolesActives,
            'demandes_en_attente' => $demandesAttente,
            'demandes_rejetees' => $demandesRejetees,
            'statut' => [
                'aucune_ecole' => $ecolesActives->isEmpty(),
                'demandes_en_attente_count' => $demandesAttente->count(),
                'demandes_rejetees_count' => $demandesRejetees->count(),
            ],
        ]);
    }

    // Historique des écoles traitées par le Super Admin
    public function ecolesTraitees(Request $request) {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $ecoles = Ecole::select([
                'id', 'nom_officiel', 'ville', 'pays', 'type_etablissement',
                'email_principal', 'nom_responsable', 'statut', 'motif_refus', 'created_at'
            ])
            ->whereIn('statut', ['active', 'refuse'])
            ->orderByDesc('updated_at')
            ->get();

        return response()->json($ecoles);
    }

    // Supprimer une école du système
    public function supprimer(Request $request, $id) {
        if ($request->user()->role !== 'super_admin') {
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        $ecole = Ecole::findOrFail($id);
        $ecole->membres()->delete();
        $ecole->codes()->delete();
        $ecole->delete();

        return response()->json(['message' => 'École supprimée avec succès.']);
    }

    // Mes écoles (pour l'utilisateur connecté)
    public function mesEcoles(Request $request) {
        $user = $request->user();

        $membres = MembreEcole::with('ecole')
            ->where('user_id', $user->id)
            ->where('statut', 'actif')
            ->get();

        return response()->json($membres);
    }

    // Rejoindre une école avec un code
    public function rejoindre(Request $request) {
        $request->validate([
            'code' => 'required|string',
        ]);

        $code = strtoupper($request->code);
        $codeInvitation = CodeInvitation::where('code', $code)
            ->where('utilise', false)
            ->first();

        if (!$codeInvitation) {
            return response()->json([
                'message' => 'Code invalide ou déjà utilisé.'
            ], 422);
        }

        $user = $request->user();

        // Créer la demande
        $membre = MembreEcole::create([
            'user_id'          => $user->id,
            'ecole_id'         => $codeInvitation->ecole_id,
            'role'             => $codeInvitation->role,
            'statut'           => $codeInvitation->role === 'admin' ? 'actif' : 'en_attente',
            'code_utilise'     => $code,
            'niveau'           => $request->niveau,
            'matricule'        => $request->matricule,
            'annee_entree'     => $request->annee_entree,
            'statut_etudiant'  => $request->statut_etudiant,
            'tuteur_nom'       => $request->tuteur_nom,
            'tuteur_tel'       => $request->tuteur_tel,
            'matiere_principale' => $request->matiere_principale,
            'diplome'          => $request->diplome,
            'experience_annees'=> $request->experience_annees,
            'type_contrat'     => $request->type_contrat,
            'poste'            => $request->poste,
            'service'          => $request->service,
            'niveau_acces'     => $request->niveau_acces,
        ]);

        // Marquer le code comme utilisé
        $codeInvitation->update(['utilise' => true]);

        // Si admin → rôle mis à jour
        if ($codeInvitation->role === 'admin') {
            $user->update(['role' => 'admin']);
        }

        return response()->json([
            'message' => $codeInvitation->role === 'admin'
                ? 'Vous êtes maintenant administrateur de cette école.'
                : 'Demande soumise. En attente de validation par l\'administration.',
            'membre'  => $membre,
            'ecole'   => $codeInvitation->ecole,
            'role'    => $codeInvitation->role,
            'statut'  => $membre->statut,
        ]);
    }

    // Demandes en attente pour l'admin de l'école
    public function demandesEnAttente(Request $request) {
        $user = $request->user();

        \Log::info('DemandesEnAttente - User ID: ' . $user->id . ', Role: ' . $user->role);

        $membre = MembreEcole::where('user_id', $user->id)
            ->where('role', 'admin')
            ->where('statut', 'actif')
            ->first();

        if (!$membre) {
            \Log::info('DemandesEnAttente - No active admin membership found for user ' . $user->id);
            return response()->json(['message' => 'Accès refusé'], 403);
        }

        \Log::info('DemandesEnAttente - Found admin membership for ecole_id: ' . $membre->ecole_id);

        $demandes = MembreEcole::with('user')
            ->where('ecole_id', $membre->ecole_id)
            ->where('statut', 'en_attente')
            ->get();

        \Log::info('DemandesEnAttente - Found ' . $demandes->count() . ' pending requests');

        return response()->json($demandes);
    }

    // Accepter une demande
    public function accepterDemande(Request $request, $id) {
        $demande = MembreEcole::findOrFail($id);
        $demande->update([
            'statut' => 'actif',
            'validated_by' => $request->user()->id,
            'validated_at' => now(),
            'joined_at' => now(),
        ]);

        // Mettre à jour le rôle de l'utilisateur
        $demande->user->update(['role' => $demande->role]);

        return response()->json(['message' => 'Demande acceptée.']);
    }

    // Rejeter une demande
    public function rejeterDemande(Request $request, $id) {
        $demande = MembreEcole::findOrFail($id);
        $demande->update([
            'statut'       => 'rejete',
            'motif_rejet'  => $request->motif ?? 'Demande rejetée',
            'validated_by' => $request->user()->id,
            'validated_at' => now(),
        ]);

        return response()->json(['message' => 'Demande rejetée.']);
    }
}