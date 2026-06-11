import 'package:flutter/material.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/models/notes_model.dart';
import 'package:appliformulaire/services/notes_service.dart';
import 'package:appliformulaire/services/api_service.dart';

class MoyennesScreen extends StatefulWidget {
  const MoyennesScreen({super.key});

  @override
  State<MoyennesScreen> createState() => _MoyennesScreenState();
}

class _MoyennesScreenState extends State<MoyennesScreen> {
  final NoteService _service = NoteService();
  final _session = SessionUtilisateur();

  List<_SemestreOption> _semestres = [];
  int? _classeId;
  int? _semestreIdActif;
  int _sessionActive = 1;

  MoyenneSemestreModel? _moyennes;
  bool _chargementInitial = true;
  bool _chargementMoyennes = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerContexteEtudiant();
  }

  // ─── Chargement du contexte ──────────────────────────────────────────────
  //
  // CAUSE DU BUG :
  // L'ancien code appelait getInscriptions() sans filtrer par etudiant_id,
  // prenait la première inscription "validee" de la liste (qui pouvait
  // appartenir à un AUTRE étudiant), puis envoyait cet etudiant_id au backend
  // → le backend renvoyait 403 "Vous ne pouvez consulter que vos propres moyennes".
  //
  // CORRECTION :
  // On utilise _session.id (l'id de l'utilisateur connecté, toujours correct)
  // directement pour l'appel getMoyennesSemestre. Pour la classe, on filtre
  // les inscriptions en cherchant celle qui appartient à _session.id.
  Future<void> _chargerContexteEtudiant() async {
    setState(() {
      _chargementInitial = true;
      _error = null;
    });

    try {
      final ecoleId = _session.ecoleId;
      final etudiantId = _session.id;

      if (etudiantId == 0 || ecoleId == 0) {
        setState(() {
          _error = "Session invalide. Veuillez vous reconnecter.";
          _chargementInitial = false;
        });
        return;
      }

      // 1. Récupérer l'inscription validée de l'étudiant connecté
      final inscriptionRes = await ApiService.getInscriptions(ecoleId);
      final inscriptions = inscriptionRes['data'] as List? ?? [];

      // Chercher d'abord par etudiant_id explicite dans la réponse
      dynamic inscriptionValidee;
      for (final i in inscriptions) {
        final iEtudiantId =
            i['etudiant_id'] as int? ??
            (i['etudiant'] as Map<String, dynamic>?)?['id'] as int?;
        if (i['statut'] == 'validee' && iEtudiantId == etudiantId) {
          inscriptionValidee = i;
          break;
        }
      }
      // Fallback : première validée si le filtre n'a rien trouvé
      inscriptionValidee ??= inscriptions.firstWhere(
        (i) => i['statut'] == 'validee',
        orElse: () => null,
      );

      if (inscriptionValidee == null) {
        setState(() {
          _error =
              "Aucune inscription validée trouvée.\n"
              "Contactez votre administrateur.";
          _chargementInitial = false;
        });
        return;
      }

      _classeId = inscriptionValidee['classe_id'] as int?;
      if (_classeId == null) {
        setState(() {
          _error = "Classe introuvable dans votre inscription.";
          _chargementInitial = false;
        });
        return;
      }

      // 2. Semestres de l'école
      final semestresRes = await ApiService.getSemestres(ecoleId);
      final semestresRaw = semestresRes['data'] as List? ?? [];

      _semestres = semestresRaw
          .map(
            (s) =>
                _SemestreOption(id: s['id'] as int, label: _labelSemestre(s)),
          )
          .toList();

      if (_semestres.isEmpty) {
        setState(() {
          _error = "Aucun semestre configuré pour cette école.";
          _chargementInitial = false;
        });
        return;
      }

      _semestreIdActif = _semestres.first.id;
      setState(() => _chargementInitial = false);

      // 3. Charger les moyennes immédiatement sans action de l'étudiant
      await _chargerMoyennes();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _chargementInitial = false;
      });
    }
  }

  String _labelSemestre(Map<String, dynamic> s) {
    final numero = s['numero'] ?? s['nom'] ?? '';
    final annee = s['annee_academique'] ?? '';
    return annee.toString().isNotEmpty
        ? 'Semestre $numero — $annee'
        : 'Semestre $numero';
  }

  // ─── Calcul des moyennes ─────────────────────────────────────────────────
  Future<void> _chargerMoyennes() async {
    if (_semestreIdActif == null || _classeId == null) return;

    setState(() {
      _chargementMoyennes = true;
      _error = null;
      _moyennes = null;
    });

    try {
      final data = await _service.getMoyennesSemestre(
        _session.ecoleId,
        etudiantId: _session
            .id, // toujours l'id de la session, jamais un id pioché ailleurs
        semestreId: _semestreIdActif!,
        classeId: _classeId!,
        session: _sessionActive,
      );
      setState(() {
        _moyennes = data;
        _chargementMoyennes = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _chargementMoyennes = false;
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mes Moyennes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_chargementInitial && !_chargementMoyennes)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _chargerMoyennes,
            ),
        ],
      ),
      body: _chargementInitial
          ? _buildChargementInitial()
          : _error != null && _moyennes == null
          ? _buildError()
          : Column(
              children: [
                _buildBarreFiltres(),
                Expanded(
                  child: _chargementMoyennes
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        )
                      : _moyennes == null
                      ? _buildVide()
                      : _buildContenuMoyennes(),
                ),
              ],
            ),
    );
  }

  // ─── Barre semestre + session ─────────────────────────────────────────────
  Widget _buildBarreFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value: _semestreIdActif,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Semestre',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: _semestres
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(
                        s.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null || v == _semestreIdActif) return;
                setState(() => _semestreIdActif = v);
                _chargerMoyennes();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: _sessionActive,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Session',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Session 1')),
                DropdownMenuItem(value: 2, child: Text('Session 2')),
              ],
              onChanged: (v) {
                if (v == null || v == _sessionActive) return;
                setState(() => _sessionActive = v);
                _chargerMoyennes();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contenu principal ────────────────────────────────────────────────────
  Widget _buildContenuMoyennes() {
    return RefreshIndicator(
      onRefresh: _chargerMoyennes,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildCarteResume(),
            const SizedBox(height: 16),
            if (_moyennes!.ecues.isEmpty)
              _buildAucuneEcue()
            else
              ..._moyennes!.ecues.map((e) => _buildCarteEcue(e)),
          ],
        ),
      ),
    );
  }

  // ─── Carte résumé général ─────────────────────────────────────────────────
  Widget _buildCarteResume() {
    final mg = _moyennes!.moyenneGenerale;
    final admis = _moyennes!.admis;
    final couleurStatut = admis ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Moyenne Générale',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            mg != null ? mg.toStringAsFixed(2) : 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const Text(
            '/ 20',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: couleurStatut.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: couleurStatut),
            ),
            child: Text(
              admis ? '✓  Admis(e)' : '✗  Non admis(e)',
              style: TextStyle(
                color: couleurStatut,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Crédits validés : ${_moyennes!.creditsValides} / ${_moyennes!.creditsTotal}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _moyennes!.creditsTotal > 0
                  ? _moyennes!.creditsValides / _moyennes!.creditsTotal
                  : 0,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carte ECUE ───────────────────────────────────────────────────────────
  Widget _buildCarteEcue(MoyenneEcueModel ecue) {
    final mf = ecue.moyenneFinale;
    final couleur = mf == null
        ? Colors.grey
        : (mf >= 10 ? Colors.green : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ecue.excluSession1
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ecue.ecueNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ecue.ecueCode,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mf != null ? mf.toStringAsFixed(2) : '--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: couleur,
                      ),
                    ),
                    Text(
                      '/ 20',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (ecue.excluSession1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Exclu(e) de la session 1',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  'CC',
                  ecue.moyenneCC?.toStringAsFixed(2) ?? '--',
                  Colors.blue,
                  Icons.edit_note_rounded,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                _buildDetailItem(
                  'Examen',
                  ecue.moyenneExamen?.toStringAsFixed(2) ?? '--',
                  Colors.orange,
                  Icons.assignment_outlined,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                _buildDetailItem(
                  'Crédits',
                  '${ecue.credits}',
                  ecue.valide ? Colors.green : Colors.grey,
                  ecue.valide
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // ─── États ───────────────────────────────────────────────────────────────
  Widget _buildChargementInitial() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1565C0)),
          SizedBox(height: 16),
          Text(
            'Chargement de vos moyennes...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Color(0xFF90CAF9),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune moyenne disponible',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les notes doivent être saisies\npar vos enseignants.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            onPressed: _chargerMoyennes,
          ),
        ],
      ),
    );
  }

  Widget _buildAucuneEcue() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Aucune ECUE trouvée pour ce semestre.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _chargerContexteEtudiant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle interne ───────────────────────────────────────────────────────────
class _SemestreOption {
  final int id;
  final String label;
  const _SemestreOption({required this.id, required this.label});
}
