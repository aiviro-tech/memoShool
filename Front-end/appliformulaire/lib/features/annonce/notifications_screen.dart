import 'package:flutter/material.dart';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_model.dart';
import 'package:appliformulaire/features/annonce/annonce_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  final _session = SessionUtilisateur();

  List<NotificationModel> _notifications = [];
  bool _loading = true;
  bool? _filtreLu;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerNotifications();
  }

  Future<void> _chargerNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifs = await _service.getNotifications(
        _session.ecoleId,
        lu: _filtreLu,
      );
      setState(() {
        _notifications = notifs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _marquerLue(NotificationModel notif) async {
    if (notif.lu) return;
    try {
      await _service.marquerLue(_session.ecoleId, notif.id);
      _chargerNotifications();
    } catch (_) {}
  }

  Future<void> _marquerToutesLues() async {
    try {
      await _service.marquerToutesLues(_session.ecoleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications marquées comme lues'),
            backgroundColor: app.AppColors.green,
          ),
        );
        _chargerNotifications();
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

  Future<void> _supprimer(NotificationModel notif) async {
    try {
      await _service.supprimer(_session.ecoleId, notif.id);
      setState(() => _notifications.removeWhere((n) => n.id == notif.id));
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

  int get _nbNonLues => _notifications.where((n) => !n.lu).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_nbNonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_nbNonLues',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: app.AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_nbNonLues > 0)
            TextButton(
              onPressed: _marquerToutesLues,
              child: const Text(
                'Tout lire',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filtreChip('Toutes', null),
                const SizedBox(width: 8),
                _filtreChip('Non lues', false),
                const SizedBox(width: 8),
                _filtreChip('Lues', true),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : _notifications.isEmpty
                ? _buildVide()
                : RefreshIndicator(
                    onRefresh: _chargerNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _buildCarteNotification(_notifications[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteNotification(NotificationModel notif) {
    final couleur = _couleurType(notif.type);
    final icone = _iconeType(notif.type);

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _supprimer(notif),
      child: GestureDetector(
        onTap: () => _marquerLue(notif),
        child: Container(
          decoration: BoxDecoration(
            color: notif.lu
                ? Colors.white
                : app.AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notif.lu
                  ? Colors.grey.shade200
                  : app.AppColors.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, color: couleur, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.titre,
                              style: TextStyle(
                                fontWeight: notif.lu
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!notif.lu)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: app.AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.contenu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _badgeType(notif.type, couleur),
                          const Spacer(),
                          Text(
                            '${notif.dateFormatee} ${notif.heureFormatee}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
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
        ),
      ),
    );
  }

  Widget _filtreChip(String label, bool? value) {
    final selected = _filtreLu == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filtreLu = value);
        _chargerNotifications();
      },
      selectedColor: app.AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: app.AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? app.AppColors.primary : Colors.grey.shade700,
        fontSize: 12,
      ),
    );
  }

  Widget _badgeType(String type, Color color) {
    final labels = {
      'annonce': 'Annonce',
      'note': 'Note',
      'support': 'Support',
      'emploi_du_temps': 'Emploi du temps',
      'paiement': 'Paiement',
      'absence': 'Absence',
      'general': 'Général',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[type] ?? type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'annonce':
        return Colors.purple;
      case 'note':
        return Colors.blue;
      case 'support':
        return Colors.teal;
      case 'emploi_du_temps':
        return Colors.indigo;
      case 'paiement':
        return Colors.green;
      case 'absence':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconeType(String type) {
    switch (type) {
      case 'annonce':
        return Icons.campaign_rounded;
      case 'note':
        return Icons.grade_rounded;
      case 'support':
        return Icons.attach_file_rounded;
      case 'emploi_du_temps':
        return Icons.schedule_rounded;
      case 'paiement':
        return Icons.payment_rounded;
      case 'absence':
        return Icons.event_busy_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _filtreLu == false
                ? 'Aucune notification non lue'
                : 'Aucune notification',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
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
            onPressed: _chargerNotifications,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}