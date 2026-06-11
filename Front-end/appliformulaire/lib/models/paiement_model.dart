// lib/models/paiement_model.dart
import 'dart:ui';

// ─── Helper : convertit n'importe quoi en double ─────────────────────────────
// Corrige le cas où le backend renvoie "675000.00" (String) au lieu de 675000.0
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// ─── Modèle Échéance ─────────────────────────────────────────────────────────
class EcheanceModel {
  final int id;
  final int numero;
  final double montant;
  final String dateLimite;
  final String? libelle;

  EcheanceModel({
    required this.id,
    required this.numero,
    required this.montant,
    required this.dateLimite,
    this.libelle,
  });

  factory EcheanceModel.fromJson(Map<String, dynamic> json) {
    return EcheanceModel(
      id:         json['id'],
      numero:     json['numero'],
      montant:    _toDouble(json['montant']),   // ← fix
      dateLimite: json['date_limite'] ?? '',
      libelle:    json['libelle'],
    );
  }

  bool get estEnRetard {
    final date = DateTime.tryParse(dateLimite);
    if (date == null) return false;
    return DateTime.now().isAfter(date);
  }

  String get dateLimiteFormatee {
    final date = DateTime.tryParse(dateLimite);
    if (date == null) return dateLimite;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ─── Modèle Type de frais ────────────────────────────────────────────────────
class TypeFraisModel {
  final int id;
  final String libelle;
  final double montant;
  final bool obligatoire;

  TypeFraisModel({
    required this.id,
    required this.libelle,
    required this.montant,
    required this.obligatoire,
  });

  factory TypeFraisModel.fromJson(Map<String, dynamic> json) {
    return TypeFraisModel(
      id:          json['id'],
      libelle:     json['libelle'] ?? '',
      montant:     _toDouble(json['montant']),   // ← fix
      obligatoire: json['obligatoire'] == true || json['obligatoire'] == 1,
    );
  }
}

// ─── Modèle Frais Étudiant (résumé complet) ──────────────────────────────────
class FraisEtudiantModel {
  final double montantTotal;
  final double montantPaye;
  final double soldeRestant;
  final List<EcheanceModel> echeances;
  final List<TypeFraisModel> typesFrais;
  final int? inscriptionId;
  final String? anneeAcademique;
  final String? nomClasse;

  /// true si au moins un TypeFrais est défini pour la classe
  final bool fraisConfigures;

  /// true si la scolarité est entièrement réglée
  final bool scolariteSoldee;

  FraisEtudiantModel({
    required this.montantTotal,
    required this.montantPaye,
    required this.soldeRestant,
    required this.echeances,
    required this.typesFrais,
    this.inscriptionId,
    this.anneeAcademique,
    this.nomClasse,
    required this.fraisConfigures,
    required this.scolariteSoldee,
  });

  factory FraisEtudiantModel.fromJson(Map<String, dynamic> json) {
    // Le backend renvoie { success, data: { ... } }
    // Le service peut passer soit la réponse brute, soit déjà data
    final data = json['data'] ?? json;

    final inscription = data['inscription'] as Map<String, dynamic>? ?? {};
    final classe      = inscription['classe'] as Map<String, dynamic>? ?? {};

    return FraisEtudiantModel(
      montantTotal:    _toDouble(data['montant_total']),   // ← fix
      montantPaye:     _toDouble(data['montant_paye']),    // ← fix
      soldeRestant:    _toDouble(data['solde_restant']),   // ← fix
      inscriptionId:   inscription['id'],
      anneeAcademique: inscription['annee_academique'],
      nomClasse:       classe['nom'],

      echeances: (data['echeances'] as List? ?? [])
          .map((e) => EcheanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),

      typesFrais: (data['types_frais'] as List? ?? [])
          .map((e) => TypeFraisModel.fromJson(e as Map<String, dynamic>))
          .toList(),

      // Lit le champ explicite envoyé par le backend.
      // Fallback : déduit depuis typesFrais si champ absent.
      fraisConfigures: data['frais_configures'] == true ||
          (data['frais_configures'] == null &&
              (data['types_frais'] as List? ?? []).isNotEmpty),

      scolariteSoldee: data['scolarite_soldee'] == true,
    );
  }

  /// Pourcentage payé (entre 0.0 et 1.0)
  double get pourcentagePaye =>
      montantTotal > 0 ? (montantPaye / montantTotal).clamp(0.0, 1.0) : 0.0;

  /// Utilise scolariteSoldee (fourni par le backend)
  /// et non soldeRestant <= 0 (incorrect quand frais non configurés)
  bool get estSolde => scolariteSoldee;
}

// ─── Modèle Paiement ─────────────────────────────────────────────────────────
class PaiementModel {
  final int id;
  final double montant;
  final String statut; // 'pending', 'approved', 'declined', 'canceled'
  final String modePaiement; // 'mtn_money', 'moov_money'
  final String? numeroRecu;
  final String? datePaiement;
  final String? recu;
  final String createdAt;
  final String currency;
  final String? fedapayTransactionId;
  final String? referencesPaiement;

  PaiementModel({
    required this.id,
    required this.montant,
    required this.statut,
    required this.modePaiement,
    this.numeroRecu,
    this.datePaiement,
    this.recu,
    required this.createdAt,
    this.currency = 'XOF',
    this.fedapayTransactionId,
    this.referencesPaiement,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id:                   json['id'],
      montant:              _toDouble(json['montant']),   // ← fix
      statut:               json['statut'] ?? 'pending',
      modePaiement:         json['mode_paiement'] ?? '',
      numeroRecu:           json['numero_recu'],
      datePaiement:         json['date_paiement'],
      recu:                 json['recu'],
      createdAt:            json['created_at'] ?? '',
      currency:             json['currency'] ?? 'XOF',
      fedapayTransactionId: json['fedapay_transaction_id'],
      referencesPaiement:   json['reference_paiement'],
    );
  }

  bool get estApprouve  => statut == 'approved';
  bool get estEnAttente => statut == 'pending';
  bool get estAnnule    => statut == 'canceled';
  bool get estRefuse    => statut == 'declined';
  bool get aRecu        => recu != null && recu!.isNotEmpty;

  Color get couleurStatut {
    switch (statut) {
      case 'approved': return const Color(0xFF2E7D32);
      case 'canceled': return const Color(0xFFF44336);
      case 'declined': return const Color(0xFFB71C1C);
      default:         return const Color(0xFFE65100);
    }
  }

  String get libelleStatut {
    switch (statut) {
      case 'approved': return 'Approuvé';
      case 'canceled': return 'Annulé';
      case 'declined': return 'Refusé';
      default:         return 'En attente';
    }
  }

  String get libelleMode {
    switch (modePaiement) {
      case 'mtn_money':  return 'MTN MoMo';
      case 'moov_money': return 'Moov Money';
      default:           return modePaiement;
    }
  }

  String get iconeMode {
    switch (modePaiement) {
      case 'mtn_money':  return '🟡';
      case 'moov_money': return '🔵';
      default:           return '💳';
    }
  }

  String get dateFormatee {
    if (createdAt.length < 10) return createdAt;
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return createdAt.substring(0, 10);
    }
  }
}