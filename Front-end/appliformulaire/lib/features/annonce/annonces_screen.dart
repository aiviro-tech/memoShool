import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_model.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_service.dart';
import 'package:appliformulaire/features/annonce/creer_annonce_screen.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  final _service = AnnonceService();
  final _session = SessionUtilisateur();

  List<AnnonceModel> _annonces = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerAnnonces();
  }

  Future<void> _chargerAnnonces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final annonces = await _service.getAnnonces(_session.ecoleId);
      setState(() {
        _annonces = annonces;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _supprimerAnnonce(AnnonceModel annonce) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Supprimer l\'annonce'),
        content: Text('Voulez-vous supprimer "${annonce.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: app.AppColors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await _service.supprimerAnnonce(_session.ecoleId, annonce.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce supprimée'),
            backgroundColor: app.AppColors.green,
          ),
        );
        _chargerAnnonces();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _publierAnnonce(AnnonceModel annonce) async {
    try {
      await _service.publierAnnonce(_session.ecoleId, annonce.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce publiée !'),
            backgroundColor: app.AppColors.green,
          ),
        );
        _chargerAnnonces();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: app.AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.estAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Annonces',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: app.AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerAnnonces,
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: 'Nouvelle annonce',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreerAnnonceScreen()),
                );
                _chargerAnnonces();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _annonces.isEmpty
          ? _buildVide()
          : RefreshIndicator(
              onRefresh: _chargerAnnonces,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _annonces.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _buildCarteAnnonce(_annonces[i], isAdmin),
              ),
            ),
    );
  }

  Widget _buildCarteAnnonce(AnnonceModel annonce, bool isAdmin) {
    final couleurCible = _couleurCible(annonce.cible);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: !annonce.publie
            ? const BorderSide(color: Colors.orange, width: 1)
            : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetailAnnonce(annonce, isAdmin),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: couleurCible.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: couleurCible,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          annonce.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _badge(annonce.cibleLabel, couleurCible),
                            if (!annonce.publie) ...[
                              const SizedBox(width: 6),
                              _badge('Brouillon', Colors.orange),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (action) async {
                        if (action == 'modifier') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreerAnnonceScreen(annonce: annonce),
                            ),
                          );
                          _chargerAnnonces();
                        } else if (action == 'publier') {
                          _publierAnnonce(annonce);
                        } else if (action == 'supprimer') {
                          _supprimerAnnonce(annonce);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'modifier',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        if (!annonce.publie)
                          const PopupMenuItem(
                            value: 'publier',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.publish,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Publier'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                annonce.contenu,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    annonce.publiePar ?? 'Admin',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    annonce.dateFormatee,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailAnnonce(AnnonceModel annonce, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                annonce.titre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(annonce.cibleLabel, _couleurCible(annonce.cible)),
                  const SizedBox(width: 8),
                  Text(
                    annonce.dateFormatee,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                annonce.contenu,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 20),
              if (annonce.publiePar != null)
                Text(
                  'Publié par : ${annonce.publiePar}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _couleurCible(String cible) {
    switch (cible) {
      case 'etudiants':
        return Colors.blue;
      case 'enseignants':
        return Colors.green;
      default:
        return app.AppColors.primary;
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucune annonce',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (_session.estAdmin) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Créer une annonce'),
              style: ElevatedButton.styleFrom(
                backgroundColor: app.AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreerAnnonceScreen()),
                );
                _chargerAnnonces();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: app.AppColors.red),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _chargerAnnonces,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}