import 'package:flutter/material.dart';
import 'models/cours_model.dart';
import 'models/cours_data.dart';
import 'models/session_utilisateur.dart'; // ← AJOUTÉ

// ================================================
// PAGE PRINCIPALE — GESTION DES COURS
// ================================================
class CoursPage extends StatefulWidget {
  const CoursPage({super.key});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  
  final String roleUtilisateur = SessionUtilisateur().role;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Gestion des Cours'),
  automaticallyImplyLeading: false,
  actions: [
    // Bouton visible seulement pour l'admin
    if (roleUtilisateur == 'admin')
      IconButton(
        icon: const Icon(Icons.fact_check),
        tooltip: 'Valider les supports',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ValidationSupportsPage(),
          ),
        ),
      ),
  ],
  bottom: TabBar( 
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Cours'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Emploi du temps'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListeCoursPage(role: roleUtilisateur),
          EmploiDuTempsPage(),
        ],
      ),
      // Le bouton "+" apparaît seulement pour admin
      floatingActionButton: roleUtilisateur == 'admin'
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FormulaireCoursPage(cours: null),
                  ),
                );
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ================================================
// PAGE : LISTE DES COURS
// ================================================
class ListeCoursPage extends StatefulWidget {
  final String role;
  const ListeCoursPage({super.key, required this.role});

  @override
  State<ListeCoursPage> createState() => _ListeCoursPageState();
}

class _ListeCoursPageState extends State<ListeCoursPage> {
  String _recherche = '';

  List<CoursModel> get _coursFiltres {
    if (_recherche.isEmpty) return donneesCoursTest;
    return donneesCoursTest.where((c) =>
      c.titre.toLowerCase().contains(_recherche.toLowerCase()) ||
      c.enseignant.toLowerCase().contains(_recherche.toLowerCase()) ||
      c.jour.toLowerCase().contains(_recherche.toLowerCase()) ||
      c.semestre.toLowerCase().contains(_recherche.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un cours...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),

        // Compteur résultats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_coursFiltres.length} cours trouvés',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Liste des cours
        Expanded(
          child: _coursFiltres.isEmpty
              ? const Center(
                  child: Text('Aucun cours trouvé',
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _coursFiltres.length,
                  itemBuilder: (context, index) {
                    final cours = _coursFiltres[index];
                    return _CarteCours(
                      cours: cours,
                      role: widget.role,
                      onModifier: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormulaireCoursPage(cours: cours),
                          ),
                        );
                        setState(() {});
                      },
                      onSupprimer: () {
                        // Confirmation avant suppression
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: Text('Supprimer "${cours.titre}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    donneesCoursTest.removeWhere(
                                        (c) => c.id == cours.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cours supprimé'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                child: const Text('Supprimer',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onVoirDetail: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailCoursPage(cours: cours),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ================================================
// WIDGET : CARTE D'UN COURS
// ================================================
class _CarteCours extends StatelessWidget {
  final CoursModel cours;
  final String role;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  final VoidCallback onVoirDetail;

  const _CarteCours({
    required this.cours,
    required this.role,
    required this.onModifier,
    required this.onSupprimer,
    required this.onVoirDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onVoirDetail,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + menu actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cours.titre,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Menu modifier/supprimer pour admin et enseignant
                  if (role == 'admin' || role == 'enseignant')
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'modifier') onModifier();
                        if (action == 'supprimer') onSupprimer();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'modifier', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'supprimer',
                          child: Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Enseignant
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(cours.enseignant,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),

              // Jour + horaire + salle
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${cours.jour} • ${cours.horaire}',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(cours.salle,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),

              // Badges crédits + semestre
              Row(
                children: [
                  _Badge(
                      texte: '${cours.credits} crédits', couleur: Colors.blue),
                  const SizedBox(width: 8),
                  _Badge(texte: cours.semestre, couleur: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Badge coloré réutilisable
class _Badge extends StatelessWidget {
  final String texte;
  final Color couleur;
  const _Badge({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texte,
        style: TextStyle(
            fontSize: 11, color: couleur, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ================================================
// PAGE : DÉTAIL D'UN COURS
// ================================================
class DetailCoursPage extends StatelessWidget {
  final CoursModel cours;
  const DetailCoursPage({super.key, required this.cours});

  @override
  Widget build(BuildContext context) {
    // Récupère les supports de ce cours
    final supports = donneesSupportTest
        .where((s) => s.statut == 'valide')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(cours.titre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête cours
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cours.titre,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(cours.description,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informations du cours
            const Text('Informations',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _LigneInfo(icone: Icons.person, label: 'Enseignant', valeur: cours.enseignant),
            _LigneInfo(icone: Icons.calendar_today, label: 'Jour', valeur: cours.jour),
            _LigneInfo(icone: Icons.access_time, label: 'Horaire', valeur: cours.horaire),
            _LigneInfo(icone: Icons.location_on, label: 'Salle', valeur: cours.salle),
            _LigneInfo(icone: Icons.star, label: 'Crédits', valeur: '${cours.credits} crédits'),
            _LigneInfo(icone: Icons.school, label: 'Semestre', valeur: cours.semestre),

            const SizedBox(height: 20),

            // Supports de cours
            const Text('Supports de cours',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),

            supports.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Aucun support disponible',
                        style: TextStyle(color: Colors.grey)),
                  )
                : Column(
                    children: supports.map((support) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.red),
                        title: Text(support.titre,
                            style: const TextStyle(fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download,
                              color: Colors.blue),
                          onPressed: () {
                            // TODO: connecter téléchargement API
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Téléchargement en cours...')),
                            );
                          },
                        ),
                      ),
                    )).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  const _LigneInfo(
      {required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: Colors.blue, size: 20),
      title: Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: Text(valeur,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

// ================================================
// PAGE : FORMULAIRE AJOUTER / MODIFIER
// ================================================
class FormulaireCoursPage extends StatefulWidget {
  final CoursModel? cours;
  const FormulaireCoursPage({super.key, required this.cours});

  @override
  State<FormulaireCoursPage> createState() => _FormulaireCoursPageState();
}

class _FormulaireCoursPageState extends State<FormulaireCoursPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _enseignantController;
  late TextEditingController _semestreController;
  late TextEditingController _creditsController;
  late TextEditingController _salleController;
  late TextEditingController _horaireController;
  String _jourSelectionne = 'Lundi';

  final List<String> _jours = [
    'Lundi', 'Mardi', 'Mercredi',
    'Jeudi', 'Vendredi', 'Samedi'
  ];

  @override
  void initState() {
    super.initState();
    // Pré-remplir si c'est une modification
    _titreController =
        TextEditingController(text: widget.cours?.titre ?? '');
    _descriptionController =
        TextEditingController(text: widget.cours?.description ?? '');
    _enseignantController =
        TextEditingController(text: widget.cours?.enseignant ?? '');
    _semestreController =
        TextEditingController(text: widget.cours?.semestre ?? '');
    _creditsController = TextEditingController(
        text: widget.cours?.credits.toString() ?? '');
    _salleController =
        TextEditingController(text: widget.cours?.salle ?? '');
    _horaireController =
        TextEditingController(text: widget.cours?.horaire ?? '');
    _jourSelectionne = widget.cours?.jour ?? 'Lundi';
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _enseignantController.dispose();
    _semestreController.dispose();
    _creditsController.dispose();
    _salleController.dispose();
    _horaireController.dispose();
    super.dispose();
  }

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.cours == null) {
      // AJOUT
      donneesCoursTest.add(CoursModel(
        id: donneesCoursTest.isEmpty ? 1 : donneesCoursTest.last.id + 1,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        enseignant: _enseignantController.text.trim(),
        semestre: _semestreController.text.trim(),
        credits: int.tryParse(_creditsController.text) ?? 0,
        salle: _salleController.text.trim(),
        horaire: _horaireController.text.trim(),
        jour: _jourSelectionne,
      ));
    } else {
      // MODIFICATION
      final index =
          donneesCoursTest.indexWhere((c) => c.id == widget.cours!.id);
      if (index != -1) {
        donneesCoursTest[index] = CoursModel(
          id: widget.cours!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          enseignant: _enseignantController.text.trim(),
          semestre: _semestreController.text.trim(),
          credits: int.tryParse(_creditsController.text) ?? 0,
          salle: _salleController.text.trim(),
          horaire: _horaireController.text.trim(),
          jour: _jourSelectionne,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            widget.cours == null ? 'Cours ajouté !' : 'Cours modifié !'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final estModification = widget.cours != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            estModification ? 'Modifier le cours' : 'Ajouter un cours'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Champ(label: 'Titre du cours', controller: _titreController),
              const SizedBox(height: 14),
              _Champ(label: 'Enseignant', controller: _enseignantController),
              const SizedBox(height: 14),
              _Champ(label: 'Semestre (ex: L3-S1)', controller: _semestreController),
              const SizedBox(height: 14),
              _Champ(
                label: 'Crédits',
                controller: _creditsController,
                clavier: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _Champ(label: 'Salle', controller: _salleController),
              const SizedBox(height: 14),
              _Champ(
                  label: 'Horaire (ex: 08h00 - 10h00)',
                  controller: _horaireController),
              const SizedBox(height: 14),

              // Sélecteur de jour
              DropdownButtonFormField<String>(
                value: _jourSelectionne,
                decoration: InputDecoration(
                  labelText: 'Jour',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _jours
                    .map((jour) =>
                        DropdownMenuItem(value: jour, child: Text(jour)))
                    .toList(),
                onChanged: (v) => setState(() => _jourSelectionne = v!),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enregistrer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    estModification
                        ? 'Enregistrer les modifications'
                        : 'Ajouter le cours',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Champ de texte réutilisable dans le formulaire
class _Champ extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType clavier;

  const _Champ({
    required this.label,
    required this.controller,
    this.clavier = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: clavier,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? 'Champ obligatoire' : null,
    );
  }
}

// ================================================
// PAGE : EMPLOI DU TEMPS
// ================================================
class EmploiDuTempsPage extends StatelessWidget {
  final List<String> _jours = [
    'Lundi', 'Mardi', 'Mercredi',
    'Jeudi', 'Vendredi', 'Samedi'
  ];

  EmploiDuTempsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _jours.length,
      itemBuilder: (context, index) {
        final jour = _jours[index];
        final coursduJour = donneesCoursTest
            .where((c) => c.jour == jour)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du jour
            Container(
              margin: const EdgeInsets.only(bottom: 8, top: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                jour,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),

            // Cours du jour ou message vide
            if (coursduJour.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Pas de cours',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              )
            else
              ...coursduJour.map(
                (cours) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.access_time,
                        color: Colors.blue),
                    title: Text(cours.titre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${cours.horaire} • ${cours.salle}'),
                    trailing: Text(cours.enseignant,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
// ================================================
// PAGE : VALIDATION DES SUPPORTS (Admin)
// ================================================
class ValidationSupportsPage extends StatefulWidget {
  const ValidationSupportsPage({super.key});

  @override
  State<ValidationSupportsPage> createState() => _ValidationSupportsPageState();
}

class _ValidationSupportsPageState extends State<ValidationSupportsPage> {

  // Filtre : on affiche seulement les supports en attente
  List<SupportModel> get _supportsEnAttente {
    return donneesSupportTest
        .where((s) => s.statut == 'en_attente')
        .toList();
  }

  void _valider(SupportModel support) {
    setState(() {
      final index = donneesSupportTest.indexOf(support);
      donneesSupportTest[index] = SupportModel(
        id: support.id,
        titre: support.titre,
        fichierPath: support.fichierPath,
        statut: 'valide',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support validé avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejeter(SupportModel support) {
    setState(() {
      final index = donneesSupportTest.indexOf(support);
      donneesSupportTest[index] = SupportModel(
        id: support.id,
        titre: support.titre,
        fichierPath: support.fichierPath,
        statut: 'rejete',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support rejeté'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation des supports')),
      body: _supportsEnAttente.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.green),
                  SizedBox(height: 12),
                  Text('Aucun support en attente',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _supportsEnAttente.length,
              itemBuilder: (context, index) {
                final support = _supportsEnAttente[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du support
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                support.titre,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Badge statut
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'En attente de validation',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Boutons valider / rejeter
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _valider(support),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Valider'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _rejeter(support),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Rejeter'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}