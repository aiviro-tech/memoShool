# SHOOLSHIP - Validation du Cahier des Charges (v1.0)

## Résumé de l'implémentation

Date: 2026-04-07
Statut: **EN COURS DE VALIDATION**

### Sections du Cahier des Charges

#### ✅ §1 - Objectif du Système
- [x] Système de gestion scolaire central
- [x] Multi-écoles supporté (architecture DB)
- [x] Codes d'invitation pour rejoindre l'école

#### ✅ §2 - Acteurs et Rôles
- [x] Super Admin (rôle: super_admin) - Peut valider les écoles
- [x] Admin Écoles (rôle: admin_ecole) - Crée écoles
- [x] Admin Écoles (role: admin dans MembreEcole) - Gère l'école
- [x] Enseignants (role: enseignant)
- [x] Étudiants (role: etudiant)

---

## FLUXS IMPLÉMENTÉS

### §3.1 - Création École
**Statut:** ✅ IMPLÉMENTÉ

**Comment:** 
- POST /api/ecoles → EcoleController@store
- Validation requise: nom_officiel, adresse, ville, etc.
- Créé en statut "en_attente" jusqu'à validation super-admin
- Admin d'école assigné automatiquement

**Test:** 
```
Admin crée école → Statut "en_attente" → Super-admin valide → 3 codes auto-générés
```

---

### §3.2 - Inscription Utilisateur
**Statut:** ✅ IMPLÉMENTÉ (AMÉLIORÉ)

**Champs collectés:**
- ✅ first_name, last_name
- ✅ email (unique)
- ✅ password (min 8 car)
- ✅ date_of_birth (format JJ/MM/AAAA, nullable)
- ✅ gender (M/F/other, nullable)
- ✅ nationality (string, nullable)
- ✅ phone (string, nullable)

**Flow:**
1. Frontend Inscription collecte tous les champs
2. Frontend mappe: "Masculin"→"M", "Féminin"→"F", "Autre"→"other"
3. Envoi à POST /api/register avec tous les paramètres
4. Backend crée User avec tous les champs
5. OTP généré et envoyé par email
6. User vérifie email avec OTP
7. Account actif après vérification

**Validation de test:**
- Email: ✅ Unique
- Password: ✅ Confirmé (frontend)
- Date de naissance: ✅ Format validé
- Sexe: ✅ Enum validé (M/F/other)
- Nationalité: ✅ String
- Téléphone: ✅ Optionnel

---

### §3.3 - Rejoindre une École
**Statut:** ✅ IMPLÉMENTÉ

**Flow 3 étapes:**
1. **Saisie du code:** User entre code d'invitation
   - POST /api/codes/verifier → Valide code existence
   - Retourne role autorisé (etudiant/enseignant/admin)

2. **Infos complémentaires:** Basé sur le rôle
   - Étudiants: classe, matricule (TODO: frontend)
   - Enseignants: diplôme, spécialité (TODO: frontend)
   - Admins: aucune (acceptés directement)

3. **Confirmation:** POST /api/rejoindre
   - Crée MembreEcole en statut "en_attente" ou "actif"
   - Si admin: "actif" immédiatement
   - Si étudiant/enseignant: dépend du mode (auto-accept TBD)

**Données:**
- ✅ Codes 3 + validation backend
- ✅ MembreEcole.role stocké
- ✅ MembreEcole.statut (en_attente/actif/rejete)

---

### §3.4 - Validation des Demandes
**Statut:** ✅ BACKEND - ⏳ FRONTEND

**Admin peut valider:**
- ✅ Backend API: PUT /api/demandes/{id}/accepter
- ✅ Backend API: PUT /api/demandes/{id}/rejeter (+ motif)
- ✅ Tracked: validated_by (user_id), validated_at (timestamp)
- ✅ Tracked: joined_at (date d'acceptation)

**Frontend TODO:**
- Créer Admin Dashboard view
- Afficher "Demandes en attente"
- Boutons [Accepter] [Rejeter]
- Input motif_rejet si rejeter

---

### §3.5 - Gestion des Codes
**Statut:** ✅ BACKEND - ⏳ FRONTEND

**Automatisation (cahier §3.5.1):**
- ✅ À l'activation école: 3 codes auto-générés
  - 1 code ENS- pour enseignants
  - 1 code ETU- pour étudiants
  - 1 code ADM- pour admins
- ✅ Format: PREFIX-XXXXX (5 chiffres aléatoires)
- ✅ Unique() vérifié dans loop

**Régénération (cahier §3.5.3):**
- ⏳ Endpoint Backend: PUT /api/codes/{id}/regenerer (NOT YET)
- ⏳ Mark old code is_active=false
- ⏳ Generate new code, return new value

**Frontend TODO:**
- Admin Dashboard section "Codes d'invitation"
- Afficher 3 codes actuels (ETU-, ENS-, ADM-)
- Bouton [Régénérer code] pour chaque

---

### §3.6 - Page d'Accueil Post-Login
**Statut:** ✅ IMPLÉMENTÉ

**Page: EcolesSelectionPage** (nouveau fichier)
- ✅ Appelle GET /api/dashboard
- ✅ Display:
  - "VOS ÉCOLES" list →  écoles_actives
  - "DEMANDES EN ATTENTE" → demandes_en_attente
  - "DEMANDES REJETÉES" → demandes_rejetees
  - [Rejoindre nouvelle école] button
  - [Créer une école] button

**Navigation:**
- ✅ Post-login redirect: Connexion → EcolesSelectionPage
- ✅ Super-admin still → SuperAdminPage

---

## BASE DE DONNÉES

### §4 - Schéma de données

#### Table: users
- ✅ id, first_name, last_name (ex: John Doe)
- ✅ email, password, role
- ✅ date_of_birth (JJ/MM/AAAA format) - NOUVEAU
- ✅ gender (M/F/other) - NOUVEAU
- ✅ nationality (string) - NOUVEAU
- ✅ phone (string) - NOUVEAU
- ✅ email_verified_at, timestamps

#### Table: ecoles
- ✅ id, nom_officiel, sigle
- ✅ adresse, ville, code_postal, pays
- ✅ emails (principal, secondaire), phones (fixe, mobile)
- ✅ Responsable (nom, titre)
- ✅ statut (en_attente/active/refuse)
- ✅ admin_id (FK users)
- ✅ motif_refus, timestamps
- ✅ logo (string, nullable) - NOUVEAU (migration ajoutée)

#### Table: membres_ecole
- ✅ id, user_id (FK), ecole_id (FK)
- ✅ role (admin/enseignant/etudiant)
- ✅ statut (actif/en_attente/rejete)
- ✅ validated_by (FK users, nullable) - NOUVEAU
- ✅ validated_at (timestamp, nullable) - NOUVEAU
- ✅ joined_at (timestamp, nullable) - NOUVEAU
- ✅ timestamps

#### Table: codes_invitation
- ✅ id, ecole_id (FK), code (unique)
- ✅ role (admin/enseignant/etudiant)
- ✅ destinataire (email, nullable)
- ✅ utilise (boolean)
- ✅ genere_par (FK users)
- ✅ is_active (boolean) - NOUVEAU (pour régénération)
- ✅ timestamps

#### Table: email_otps
- ✅ Pour stockage OTP vérification email
- ✅ id, user_id, code, expires_at, is_used, timestamps

#### Table: password_reset_otps
- ✅ Pour stockage OTP reset password
- ✅ id, user_id, code, expires_at, is_used, timestamps

---

## API ENDPOINTS

### Authentification
- ✅ POST /api/register - Inscription avec profil complet
- ✅ POST /api/login - Connexion
- ✅ POST /api/logout - Déconnexion (protégé)
- ✅ POST /api/verify-email - Vérifier OTP email
- ✅ POST /api/forgot-password - Initier reset
- ✅ POST /api/reset-password - Reset avec OTP

### Écoles (protégé)
- ✅ POST /api/ecoles - Créer école
- ✅ GET /api/ecoles/en-attente - Lister écoles en attente (super-admin)
- ✅ PUT /api/ecoles/{id}/activer - Valider école + auto-generate 3 codes
- ✅ PUT /api/ecoles/{id}/refuser - Rejeter école
- ✅ GET /api/mes-ecoles - Lister mes écoles
- ✅ GET /api/dashboard - Dashboard post-login (NEW)

### Codes d'invitation (protégé)
- ✅ POST /api/codes/verifier - Vérifier code valide
- ✅ POST /api/codes/generer - Générer nouveau code (admin)
- ✅ GET /api/mes-codes - Lister mes codes (admin)
- ⏳ PUT /api/codes/{id}/regenerer - Régénérer code (NOT YET)

### Demandes d'adhésion (protégé)
- ✅ POST /api/rejoindre - Soumettre demande adhésion
- ✅ GET /api/demandes-en-attente - Lister demandes (admin)
- ✅ PUT /api/demandes/{id}/accepter - Accepter demande
- ✅ PUT /api/demandes/{id}/rejeter - Rejeter demande + motif

---

## ÉTAT DES FICHIERS

### Backend
- ✅ app/Http/Controllers/Api/AuthController.php - Enregistrement amélioré
- ✅ app/Http/Controllers/Api/EcoleController.php - Dashboard, 3 codes auto
- ✅ app/Http/Controllers/Api/CodeInvitationController.php - Gestion codes
- ✅ app/Models/User.php - Fillable avec nouveaux champs 
- ✅ app/Models/Ecole.php - Intacte
- ✅ app/Models/MembreEcole.php - Fillable validation fields
- ✅ app/Models/CodeInvitation.php - Intacte
- ✅ database/migrations/2026_04_07_140000_*.php - 4 NEW migrations
- ✅ database/seeders/TestDataSeeder.php - Données de test
- ✅ routes/api.php - Routes complètes + /dashboard

### Frontend
- ✅ lib/main.dart - Routes named + colors.secondary + EcolesSelectionPage
- ✅ lib/services/api_service.dart - register() avec 4 params + getDashboardAccueil()
- ✅ lib/ecoles_selection_page.dart - NEW page with dashboard integration
- ✅ Inscription widget - Radio buttons for gender/nationality, fetch from API register

---

## DONNÉES DE TEST

```
Admin School:
  Email: admin+1775593332@lnt.test
  Password: password
  Role: admin_ecole

School: Lycée National de Test
  Codes:
    - Étudiants: ETU-89893
    - Enseignants: ENS-78729
    - Admins: ADM-15267
```

---

## TÂCHES RESTANTES (High Priority)

### 1. ⏳ Frontend - Admin Dashboard
**Impact:** Cahier §3.4, §3.5
- Build admin_dashboard_page.dart
- List demandes_en_attente with [Accepter] [Rejeter] buttons
- Display 3 codes with [Régénérer] buttons
- Input fields for rejection motif

### 2. ⏳ Backend - Code Regeneration
**Impact:** Cahier §3.5.3
- PUT /api/codes/{id}/regenerer endpoint
- Mark old code is_active=false
- Generate new code with same role
- Return new code value

### 3. ⏳ Frontend - School Creation Page
**Impact:** Cahier §3.1
- Update EcolesPage or create new creer_ecole_page.dart
- Include logo upload field (file picker)
- Format: POST /api/ecoles with all fields

### 4. ⏳ Email Templates Update
**Impact:** Cahier Notification
- Update SchoolActivatedMail.blade.php

 to show 3 codes
- User receives email: "Votre école a été validée. Codes: ENS-..., ETU-..., ADM-..."

### 5. ⏳ Unique Constraint on MembreEcole
**Impact:** Cahier §5 Rule R2
- Migration: Add unique(user_id, ecole_id) WHERE statut='actif'
- Prevent user from joining same school twice

---

## VALIDATION CONTRE CAHIER DES CHARGES

### ✅ Conformité Complète
- Sections 1, 2, 3.1-3.3, 3.6, 4 (DB Schema)
- API de base implantée
- Frontend principal page créée
- Inscription avec profil complet
- 3 codes auto-générés

### ⏳ Conformité Partielle
- Sections 3.4, 3.5: Backend OK, Frontend à implémenter
- Sections 3.2: Profil collecté, mais pas toutes les infos complémentaires par rôle (classe, diplôme)

### ❌ Non encore traité
- Section 6 (optionnel): Gestion des fichiers (documents)
- Section 7 (optionnel): Réunions virtuelles
- Section 8: Test d'acceptation détaillés

---

## NOTES DE DÉVELOPPEMENT

**Date:** 2026-04-07
**Conventions:**
- Routes: /api/* (REST)
- Auth: Bearer tokens (Sanctum)
- Validation: Laravel validators
- Sexe utilisateur: M/F/other (code) ← "Masculin"/"Féminin"/"Autre" (frontend)
- Date naissance: JJ/MM/AAAA (string) → stockée en DATE en DB
- Codes: PREFIX-5DIGITS (unique per ecole)

**Migrations appliquées:** 4/4
**Seeders exécutés:** SuperAdminSeeder ✅, DatabaseSeeder ✅, TestDataSeeder ✅

---

**Prochaine étape:** Implémenter Admin Dashboard page (Priority: HIGH)
