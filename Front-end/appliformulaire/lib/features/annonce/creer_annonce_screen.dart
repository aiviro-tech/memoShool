import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_model.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_service.dart';

class CreerAnnonceScreen extends StatefulWidget {
  /// Si [annonce] est fourni → mode modification, sinon → mode création
  final AnnonceModel? annonce;
  const CreerAnnonceScreen({super.key, this.annonce});

  @override
  State<CreerAnnonceScreen> createState() => _CreerAnnonceScreenState();
}

class _CreerAnnonceScreenState extends State<CreerAnnonceScreen> {
  final _service = AnnonceService();
  final _session = SessionUtilisateur();
  final _formKey = GlobalKey<FormState>();

  final _titreCtrl = TextEditingController();
  final _contenuCtrl = TextEditingController();

  String _cible = 'tous';
  String? _niveauCible;
  int? _classeCibleId;
  bool _publie = false;

  List<dynamic> _classes = [];
  bool _loading = true;
  bool _submitting = false;

  bool get _modeModification => widget.annonce != null;

  final List<String> _niveaux = ['L1', 'L2', 'L3', 'M1', 'M2'];

  @override
  void initState() {
    super.initState();
    _chargerClasses();
    if (_modeModification) {
      final a = widget.annonce!;
      _titreCtrl.text = a.titre;
      _contenuCtrl.text = a.contenu;
      _cible = a.cible;
      _niveauCible = a.niveauCible;
      _classeCibleId = a.classeCibleId;
      _publie = a.publie;
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerClasses() async {
    try {
      final res = await ApiService.getClasses(_session.ecoleId);
      setState(() {
        _classes = res['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);

    final data = <String, dynamic>{
      'titre': _titreCtrl.text.trim(),
      'contenu': _contenuCtrl.text.trim(),
      'cible': _cible,
      'publie': _publie,
    };

    if (_cible == 'etudiants') {
      if (_classeCibleId != null) {
        data['classe_cible'] = _classeCibleId;
      } else if (_niveauCible != null) {
        data['niveau_cible'] = _niveauCible;
      }
    }

    try {
      if (_modeModification) {
        await _service.modifierAnnonce(
          _session.ecoleId,
          widget.annonce!.id,
          data,
        );
      } else {
        await _service.creerAnnonce(_session.ecoleId, data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _modeModification ? 'Annonce modifiée !' : 'Annonce créée !',
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  FIX 1 : Supprimé resizeToAvoidBottomInset: false
      // Le comportement par défaut (true) remonte le contenu quand le clavier apparaît
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _modeModification ? 'Modifier l\'annonce' : 'Nouvelle annonce',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                //  FIX 2 : Column externe pour séparer le scroll et le bouton fixe
                child: Column(
                  children: [
                    //  FIX 3 : SingleChildScrollView remplace la Column statique
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCard('Contenu de l\'annonce', [
                              _buildLabel('Titre *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _titreCtrl,
                                decoration: _deco(
                                  'Ex: Réunion pédagogique du lundi',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Champ requis'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Message *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _contenuCtrl,
                                maxLines: 4,
                                decoration: _deco(
                                  'Rédigez votre annonce ici...',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Champ requis'
                                    : null,
                              ),
                            ]),
                            const SizedBox(height: 12),
                            _buildCard('Destinataires', [
                              _buildLabel('Envoyer à *'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _cibleBtn(
                                    'tous',
                                    'Tout le monde',
                                    Icons.groups_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _cibleBtn(
                                    'etudiants',
                                    'Étudiants',
                                    Icons.school_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _cibleBtn(
                                    'enseignants',
                                    'Enseignants',
                                    Icons.person_rounded,
                                  ),
                                ],
                              ),
                              if (_cible == 'etudiants') ...[
                                const SizedBox(height: 14),
                                _buildLabel('Filtrer par (optionnel)'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _niveauCible,
                                  isExpanded: true,
                                  decoration: _deco(
                                    'Niveau (L1, L2, L3, M1, M2)',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Tous les niveaux'),
                                    ),
                                    ..._niveaux.map(
                                      (n) => DropdownMenuItem<String>(
                                        value: n,
                                        child: Text(n),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _niveauCible = v;
                                    if (v != null) _classeCibleId = null;
                                  }),
                                ),
                                const SizedBox(height: 10),
                                const Center(
                                  child: Text(
                                    '— ou —',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  value: _classeCibleId,
                                  isExpanded: true,
                                  decoration: _deco('Classe spécifique'),
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('Toutes les classes'),
                                    ),
                                    ..._classes.map(
                                      (c) => DropdownMenuItem<int>(
                                        value: c['id'] as int,
                                        child: Text(
                                          '${c['nom'] ?? ''} (${c['niveau'] ?? ''})',
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _classeCibleId = v;
                                    if (v != null) _niveauCible = null;
                                  }),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 12),
                            _buildCard('Publication', [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _publie,
                                activeThumbColor: AppColors.primary,
                                title: const Text(
                                  'Publier immédiatement',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  _publie
                                      ? 'L\'annonce sera visible et les notifications seront envoyées.'
                                      : 'L\'annonce sera sauvegardée en brouillon.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onChanged: (v) => setState(() => _publie = v),
                              ),
                            ]),
                            //  FIX 4 : Espace en bas pour que le dernier card
                            // ne soit pas caché derrière le bouton
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    //  FIX 5 : Bouton fixe en bas, hors du scroll
                    Container(
                      color: const Color(0xFFF5F7FA),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _modeModification
                                    ? Icons.save_rounded
                                    : Icons.send_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _submitting
                              ? 'Traitement...'
                              : _modeModification
                              ? 'Enregistrer les modifications'
                              : _publie
                              ? 'Publier l\'annonce'
                              : 'Sauvegarder en brouillon',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _submitting ? null : _soumettre,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cibleBtn(String valeur, String label, IconData icon) {
    final selected = _cible == valeur;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _cible = valeur;
          _niveauCible = null;
          _classeCibleId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String titre, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSub,
      ),
    );
  }

  InputDecoration _deco(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}
