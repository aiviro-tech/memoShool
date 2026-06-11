// lib/features/paiements/admin_paiements_screen.dart
import 'package:flutter/material.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/paiement_model.dart';
import 'package:appliformulaire/services/paiement_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appliformulaire/features/paiements/config_frais_screen.dart';

class _PC {
  static const bg = Color(0xFFF5F7FA);
  static const vert = Color(0xFF1B5E20);
  static const vertClair = Color(0xFF2E7D32);
  static const rouge = Color(0xFFC62828);
  static const orange = Color(0xFFE65100);
  static const bleu = Color(0xFF1565C0);
  static const texte = Color(0xFF1A1A2E);
  static const texteSub = Color(0xFF6B7280);
  static const blanc = Colors.white;
  static const mtn = Color(0xFFFFCC00);
  static const moov = Color(0xFF0057A8);
}

class AdminPaiementsScreen extends StatefulWidget {
  const AdminPaiementsScreen({super.key});
  @override
  State<AdminPaiementsScreen> createState() => _AdminPaiementsScreenState();
}

class _AdminPaiementsScreenState extends State<AdminPaiementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _session = SessionUtilisateur();
  final _service = PaiementService();

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _tousEtudiants = [];
  List<Map<String, dynamic>> _tousLesPaiements = [];

  int? _classeSelectionneeId;
  String _filtreStatut = 'tous';
  String _rechercheNom = '';
  final _searchCtrl = TextEditingController();

  double _totalPercu = 0;
  double _totalRestant = 0;

  bool _loading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Chargement principal ──────────────────────────────────────────────────
  Future<void> _chargerDonnees() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final ecoleId = _session.ecoleId;

      final classesRes = await ApiService.getClasses(ecoleId);
      final classes = (classesRes['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final inscriptionsRes = await ApiService.getInscriptions(
        ecoleId,
        statut: 'validee',
      );
      final inscriptions = (inscriptionsRes['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final List<Map<String, dynamic>> etudiantsData = [];
      final List<Map<String, dynamic>> tousLesPaiements = [];

      for (final inscription in inscriptions) {
        final etudiant = inscription['etudiant'] as Map<String, dynamic>?;
        final classeMap = inscription['classe'] as Map<String, dynamic>?;
        final etudiantId = etudiant?['id'] as int?;

        if (etudiantId == null || etudiant == null) continue;

        try {
          final fraisRes = await ApiService.getFraisEtudiant(
            ecoleId,
            etudiantId: etudiantId,
          );
          final frais = FraisEtudiantModel.fromJson(fraisRes);

          final hRes = await ApiService.getHistoriquePaiements(
            ecoleId,
            etudiantId: etudiantId,
          );
          final paiements = (hRes['data'] as List? ?? [])
              .map((p) => PaiementModel.fromJson(p as Map<String, dynamic>))
              .toList();

          final classeId =
              inscription['classe_id'] as int? ?? classeMap?['id'] as int?;
          final classeNom = classeMap?['nom'] as String? ?? '';

          final dejaAjoute = etudiantsData.any(
            (e) => (e['etudiant'] as Map)['id'] == etudiantId,
          );
          if (dejaAjoute) continue;

          etudiantsData.add({
            'etudiant': etudiant,
            'frais': frais,
            'paiements': paiements,
            'classe_id': classeId,
            'classe_nom': classeNom,
          });

          for (final p in paiements) {
            tousLesPaiements.add({
              'paiement': p,
              'etudiant': etudiant,
              'classe_id': classeId,
              'classe_nom': classeNom,
            });
          }
        } catch (_) {}
      }

      tousLesPaiements.sort((a, b) {
        final pa = a['paiement'] as PaiementModel;
        final pb = b['paiement'] as PaiementModel;
        return pb.createdAt.compareTo(pa.createdAt);
      });

      double totalPercu = 0, totalRestant = 0;

      for (final e in etudiantsData) {
        final f = e['frais'] as FraisEtudiantModel;
        totalPercu += f.montantPaye;
        totalRestant += f.soldeRestant;
      }

      setState(() {
        _classes = classes;
        _tousEtudiants = etudiantsData;
        _tousLesPaiements = tousLesPaiements;
        _totalPercu = totalPercu;
        _totalRestant = totalRestant;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Filtres ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _etudiantsFiltres {
    return _tousEtudiants.where((item) {
      final e = item['etudiant'] as Map<String, dynamic>;
      final nom = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'
          .toLowerCase();
      final matchClasse =
          _classeSelectionneeId == null ||
          item['classe_id'] == _classeSelectionneeId;
      final matchNom =
          _rechercheNom.isEmpty || nom.contains(_rechercheNom.toLowerCase());
      return matchClasse && matchNom;
    }).toList();
  }

  List<Map<String, dynamic>> get _paiementsFiltres {
    return _tousLesPaiements.where((item) {
      final p = item['paiement'] as PaiementModel;
      final e = item['etudiant'] as Map<String, dynamic>;
      final nom = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'
          .toLowerCase();
      final matchClasse =
          _classeSelectionneeId == null ||
          item['classe_id'] == _classeSelectionneeId;
      final matchStatut = _filtreStatut == 'tous' || p.statut == _filtreStatut;
      final matchNom =
          _rechercheNom.isEmpty || nom.contains(_rechercheNom.toLowerCase());
      return matchClasse && matchStatut && matchNom;
    }).toList();
  }

  double get _totalPercuFiltre => _etudiantsFiltres.fold(
    0,
    (s, e) => s + (e['frais'] as FraisEtudiantModel).montantPaye,
  );

  double get _totalRestantFiltre => _etudiantsFiltres.fold(
    0,
    (s, e) => s + (e['frais'] as FraisEtudiantModel).soldeRestant,
  );

  //  Approuvés filtrés par classe — recalculé à chaque rebuild
  int get _nbApprouvesFiltres => _paiementsFiltres
      .where((i) => (i['paiement'] as PaiementModel).estApprouve)
      .length;

  //  En attente filtrés par classe — recalculé à chaque rebuild
  int get _nbEnAttenteFiltres => _paiementsFiltres
      .where((i) => (i['paiement'] as PaiementModel).estEnAttente)
      .length;

  //  Taux de recouvrement : montant perçu / (perçu + restant) × 100
  double get _tauxRecouvrement {
    final percu = _classeSelectionneeId != null ? _totalPercuFiltre : _totalPercu;
    final restant = _classeSelectionneeId != null ? _totalRestantFiltre : _totalRestant;
    final total = percu + restant;
    if (total <= 0) return 0;
    return (percu / total) * 100;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      appBar: AppBar(
        title: const Text(
          'Gestion des paiements',
          style: TextStyle(
            color: _PC.blanc,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: _PC.vert,
        elevation: 0,
        iconTheme: const IconThemeData(color: _PC.blanc),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _chargerDonnees,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _PC.blanc,
          indicatorWeight: 3,
          labelColor: _PC.blanc,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_rounded, size: 18),
              text: 'Tableau de bord',
            ),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Étudiants'),
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 18),
              text: 'Transactions',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _PC.vertClair))
          : _erreur != null
          ? _buildErreur()
          : Column(
              children: [
                _buildFiltreClasse(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboard(),
                      _buildListeEtudiants(),
                      _buildTransactions(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Filtre classe global ──────────────────────────────────────────────────
  Widget _buildFiltreClasse() {
    return Container(
      color: _PC.vert,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _classeSelectionneeId,
                  dropdownColor: _PC.vert,
                  iconEnabledColor: Colors.white70,
                  hint: const Text(
                    'Toutes les classes',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  style: const TextStyle(color: _PC.blanc, fontSize: 13),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Toutes les classes'),
                    ),
                    ..._classes.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c['id'] as int?,
                        child: Text(c['nom'] as String? ?? 'Classe sans nom'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _classeSelectionneeId = v),
                ),
              ),
            ),
          ),
          if (_classeSelectionneeId != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _classeSelectionneeId = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: _PC.blanc, size: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final percuAffiche = _classeSelectionneeId != null
        ? _totalPercuFiltre
        : _totalPercu;
    final restantAffiche = _classeSelectionneeId != null
        ? _totalRestantFiltre
        : _totalRestant;
    final labelClasse = _classeSelectionneeId != null
        ? (_classes.firstWhere(
                (c) => c['id'] == _classeSelectionneeId,
                orElse: () => {},
              )['nom'] ??
              '')
        : 'Toutes les classes';

    //  Taux de recouvrement arrondi à 1 décimale
    final tauxAffiche = _tauxRecouvrement;
    final totalAttendu = percuAffiche + restantAffiche;

    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: _PC.vertClair,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bannière principale ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _PC.vertClair.withAlpha(77),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Libellé classe
                  Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.white70, size: 15),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          labelClasse,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Total perçu',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  // Montant — FittedBox évite tout overflow sur petits écrans
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${percuAffiche.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: _PC.blanc,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  //  Barre de progression du taux de recouvrement
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Taux de recouvrement',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  '${tauxAffiche.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: _PC.blanc,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: tauxAffiche / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation(
                                  tauxAffiche >= 80
                                      ? Colors.white
                                      : tauxAffiche >= 50
                                          ? Colors.white70
                                          : Colors.orange[200]!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ligne perçu / total attendu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoMini('Perçu', '${percuAffiche.toStringAsFixed(0)} FCFA'),
                      _infoMini('Attendu', '${totalAttendu.toStringAsFixed(0)} FCFA', right: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.white60, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Restant : ${restantAffiche.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 4 cartes stats — toutes filtrées par classe ───────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Étudiants',
                    '${_etudiantsFiltres.length}',
                    Icons.school_rounded,
                    _PC.bleu,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Approuvés',
                    //  FIX : getter filtré par classe
                    '$_nbApprouvesFiltres',
                    Icons.check_circle_rounded,
                    _PC.vertClair,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'En attente',
                    //  FIX : getter filtré par classe
                    '$_nbEnAttenteFiltres',
                    Icons.hourglass_top_rounded,
                    _PC.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Transactions',
                    '${_paiementsFiltres.length}',
                    Icons.receipt_rounded,
                    const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Soldes restants ───────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: _PC.orange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Soldes restants',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _PC.texte,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._buildTopSoldesRestants(),
          ],
        ),
      ),
    );
  }

  // Helper mini info dans la bannière
  Widget _infoMini(String label, String valeur, {bool right = false}) => Column(
    crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(valeur, style: const TextStyle(color: _PC.blanc, fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );

  List<Widget> _buildTopSoldesRestants() {
    final avecSolde = _etudiantsFiltres
        .where((e) => (e['frais'] as FraisEtudiantModel).soldeRestant > 0)
        .toList()
      ..sort((a, b) {
        final fa = (a['frais'] as FraisEtudiantModel).soldeRestant;
        final fb = (b['frais'] as FraisEtudiantModel).soldeRestant;
        return fb.compareTo(fa);
      });

    if (avecSolde.isEmpty) {
      return [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Tous les étudiants sont à jour !',
                style: TextStyle(color: _PC.vertClair),
              ),
            ),
          ),
        ),
      ];
    }

    return avecSolde.take(10).map((item) {
      final e = item['etudiant'] as Map<String, dynamic>;
      final f = item['frais'] as FraisEtudiantModel;
      final nom = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
      final pct = f.pourcentagePaye;
      final cNom = item['classe_nom'] as String? ?? '';

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _PC.bleu.withAlpha(26),
                child: Text(
                  nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _PC.bleu,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (cNom.isNotEmpty)
                      Text(
                        cNom,
                        style: const TextStyle(color: _PC.texteSub, fontSize: 11),
                      ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          pct > 0.6 ? _PC.vertClair : _PC.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${f.soldeRestant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _PC.rouge,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'restant',
                    style: TextStyle(color: _PC.texteSub, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  //  FIX : _statCard sans hauteur fixe, s'adapte au contenu
  Widget _statCard(String label, String valeur, IconData icon, Color couleur) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: couleur, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valeur,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: couleur,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: _PC.texteSub, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // ── Liste étudiants ───────────────────────────────────────────────────────
  Widget _buildListeEtudiants() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant...',
              prefixIcon: const Icon(Icons.search, color: _PC.vertClair),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _rechercheNom = v),
          ),
        ),
        if (_classeSelectionneeId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _PC.vertClair.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _PC.vertClair.withAlpha(51)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Étudiants', '${_etudiantsFiltres.length}', _PC.bleu),
                  _miniStat('Perçu', '${_totalPercuFiltre.toStringAsFixed(0)} FCFA', _PC.vertClair),
                  _miniStat('Restant', '${_totalRestantFiltre.toStringAsFixed(0)} FCFA', _PC.rouge),
                ],
              ),
            ),
          ),
        Expanded(
          child: _etudiantsFiltres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: _PC.texteSub.withAlpha(77)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun étudiant trouvé',
                        style: TextStyle(color: _PC.texteSub, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vérifiez que des inscriptions sont validées\npour cette école.',
                        style: TextStyle(color: _PC.texteSub, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _etudiantsFiltres.length,
                  itemBuilder: (_, i) => _buildCarteEtudiant(_etudiantsFiltres[i]),
                ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String valeur, Color couleur) => Column(
    children: [
      Text(
        valeur,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: couleur),
      ),
      Text(label, style: const TextStyle(color: _PC.texteSub, fontSize: 10)),
    ],
  );

  Widget _buildCarteEtudiant(Map<String, dynamic> item) {
    final e = item['etudiant'] as Map<String, dynamic>;
    final f = item['frais'] as FraisEtudiantModel;
    final pays = item['paiements'] as List<PaiementModel>;
    final nom = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
    final cNom = item['classe_nom'] as String? ?? '';
    final classeId = item['classe_id'] as int?;
    final etudiantId = e['id'] as int?;
    final pct = f.pourcentagePaye;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _PC.bleu.withAlpha(26),
            child: Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: const TextStyle(color: _PC.bleu, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            nom,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cNom.isNotEmpty)
                Text(cNom, style: const TextStyle(color: _PC.texteSub, fontSize: 11)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    f.estSolde ? _PC.vertClair : _PC.orange,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                !f.fraisConfigures
                    ? 'Frais non configurés'
                    : f.estSolde
                    ? '✓ Soldé'
                    : 'Restant : ${f.soldeRestant.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  color: !f.fraisConfigures
                      ? _PC.orange
                      : f.estSolde
                      ? _PC.vertClair
                      : _PC.rouge,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _miniStat2(
                        'Total',
                        !f.fraisConfigures ? '—' : '${f.montantTotal.toStringAsFixed(0)} FCFA',
                        Colors.grey[700]!,
                      ),
                      _miniStat2('Payé', '${f.montantPaye.toStringAsFixed(0)} FCFA', _PC.vertClair),
                      _miniStat2(
                        'Restant',
                        !f.fraisConfigures ? '—' : '${f.soldeRestant.toStringAsFixed(0)} FCFA',
                        f.estSolde ? _PC.vertClair : _PC.rouge,
                      ),
                    ],
                  ),
                  if (pays.isNotEmpty) ...[
                    const Divider(height: 16),
                    ...pays.take(3).map(_lignePaiement),
                    if (pays.length > 3)
                      Text(
                        '+ ${pays.length - 3} autres paiements',
                        style: const TextStyle(color: _PC.texteSub, fontSize: 12),
                      ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Aucun paiement enregistré',
                        style: TextStyle(color: _PC.texteSub, fontSize: 12),
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (classeId != null && etudiantId != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfigFraisScreen(
                                  classeId: classeId,
                                  classeNom: cNom,
                                ),
                              ),
                            );
                            if (result == true) _chargerDonnees();
                          },
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Configurer frais'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _PC.bleu,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (pays.any((p) => p.estApprouve && p.aRecu))
                        ElevatedButton.icon(
                          onPressed: () async {
                            final dernierApprouve = pays.firstWhere(
                              (p) => p.estApprouve && p.aRecu,
                              orElse: () => pays.first,
                            );
                            final uri = Uri.parse(
                              _service.getRecuUrl(_session.ecoleId, dernierApprouve.id),
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text('Voir reçu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _PC.vertClair,
                            foregroundColor: _PC.blanc,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat2(String label, String valeur, Color couleur) => Expanded(
    child: Column(
      children: [
        Text(
          valeur,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: couleur),
        ),
        Text(label, style: const TextStyle(color: _PC.texteSub, fontSize: 10)),
      ],
    ),
  );

  Widget _lignePaiement(PaiementModel p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(p.iconeMode, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(p.libelleMode, style: const TextStyle(fontSize: 12))),
        Text(
          '${p.montant.toStringAsFixed(0)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: p.couleurStatut.withAlpha(26)),
          child: Text(
            p.libelleStatut,
            style: TextStyle(color: p.couleurStatut, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  // ── Transactions ──────────────────────────────────────────────────────────
  Widget _buildTransactions() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chipFiltre('Tous', 'tous'),
                const SizedBox(width: 8),
                _chipFiltre('Approuvés', 'approved'),
                const SizedBox(width: 8),
                _chipFiltre('En attente', 'pending'),
                const SizedBox(width: 8),
                _chipFiltre('Annulés', 'canceled'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Filtrer par nom...',
              prefixIcon: const Icon(Icons.search, color: _PC.vertClair, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _rechercheNom = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_paiementsFiltres.length} transaction(s)',
                style: const TextStyle(color: _PC.texteSub, fontSize: 12),
              ),
              Text(
                'Total : ${_paiementsFiltres.where((i) => (i['paiement'] as PaiementModel).estApprouve).fold(0.0, (s, i) => s + (i['paiement'] as PaiementModel).montant).toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: _PC.vertClair,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _paiementsFiltres.isEmpty
              ? const Center(
                  child: Text('Aucune transaction', style: TextStyle(color: _PC.texteSub)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _paiementsFiltres.length,
                  itemBuilder: (_, i) => _buildCarteTransaction(_paiementsFiltres[i]),
                ),
        ),
      ],
    );
  }

  Widget _chipFiltre(String label, String valeur) {
    final sel = _filtreStatut == valeur;
    return GestureDetector(
      onTap: () => setState(() => _filtreStatut = valeur),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _PC.vertClair : _PC.blanc,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _PC.vertClair : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? _PC.blanc : _PC.texteSub,
            fontSize: 12,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCarteTransaction(Map<String, dynamic> item) {
    final p = item['paiement'] as PaiementModel;
    final e = item['etudiant'] as Map<String, dynamic>;
    final cNom = item['classe_nom'] as String? ?? '';
    final nom = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (p.modePaiement == 'mtn_money' ? _PC.mtn : _PC.moov).withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(p.iconeMode, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '${p.libelleMode}${cNom.isNotEmpty ? ' · $cNom' : ''} · ${p.dateFormatee}',
                    style: const TextStyle(color: _PC.texteSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.montant.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.couleurStatut.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.libelleStatut,
                    style: TextStyle(
                      color: p.couleurStatut,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (p.estApprouve && p.aRecu) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: _PC.vertClair, size: 20),
                onPressed: () async {
                  final uri = Uri.parse(_service.getRecuUrl(_session.ecoleId, p.id));
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErreur() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 56, color: _PC.rouge),
        const SizedBox(height: 16),
        Text(
          _erreur!,
          style: const TextStyle(color: _PC.rouge),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _PC.vertClair,
            foregroundColor: _PC.blanc,
          ),
          onPressed: _chargerDonnees,
        ),
      ],
    ),
  );
}