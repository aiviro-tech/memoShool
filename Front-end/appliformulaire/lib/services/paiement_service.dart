// lib/services/paiement_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:appliformulaire/models/paiement_model.dart';
import 'package:appliformulaire/services/api_service.dart';

class PaiementService {
  // ─── Frais & solde d'un étudiant ────────────────────────────────────────────
  Future<FraisEtudiantModel> getFraisEtudiant(
    int ecoleId, {
    int? etudiantId,
  }) async {
    final data = await ApiService.getFraisEtudiant(
      ecoleId,
      etudiantId: etudiantId,
    );
    return FraisEtudiantModel.fromJson(data);
  }

  // ─── Historique des paiements ────────────────────────────────────────────────
  Future<List<PaiementModel>> getHistorique(
    int ecoleId, {
    int? etudiantId,
  }) async {
    final data = await ApiService.getHistoriquePaiements(
      ecoleId,
      etudiantId: etudiantId,
    );
    final liste = data['data'] as List? ?? [];
    return liste.map((p) => PaiementModel.fromJson(p)).toList();
  }

  // ─── Initier un paiement MTN/Moov ───────────────────────────────────────────
  Future<Map<String, dynamic>> initierPaiement(
    int ecoleId, {
    required int inscriptionId,
    required double montant,
    required String modePaiement,
    required String telephone,
  }) async {
    try {
      final data = await ApiService.initierPaiement(
        ecoleId,
        inscriptionId: inscriptionId,
        montant: montant,
        modePaiement: modePaiement,
        telephone: telephone,
      );
      return {
        'success': data['success'] ?? false,
        'payment_url': data['data']?['payment_url'],
        'token': data['data']?['token'],
        'paiement': data['data']?['paiement'],
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // ─── Vérifier le statut d'un paiement ───────────────────────────────────────
  Future<PaiementModel?> verifierStatut(int ecoleId, int paiementId) async {
    try {
      final data = await ApiService.verifierStatutPaiement(ecoleId, paiementId);
      if (data['data'] != null) {
        return PaiementModel.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Générer le reçu PDF ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> genererRecu(int ecoleId, int paiementId) async {
    try {
      final data = await ApiService.genererRecu(ecoleId, paiementId);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? '',
        'paiement': data['data'] != null
            ? PaiementModel.fromJson(data['data'])
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // ─── Télécharger le reçu PDF en bytes (avec auth Dio) ───────────────────────
  //
  // Retourne le chemin local du fichier PDF sauvegardé.
  // Utilise Dio (qui porte déjà le token Bearer) pour éviter le 401
  // que provoquait launchUrl (navigateur externe sans token).
  //
  Future<String> telechargerRecuEnLocal(int ecoleId, int paiementId) async {
    // 1. Télécharger les bytes via Dio (token automatiquement inclus)
    final Uint8List bytes = await ApiService.telechargerRecuBytes(
      ecoleId,
      paiementId,
    );

    // 2. Choisir le répertoire de stockage selon la plateforme
    final Directory dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();

    // 3. Écrire le fichier
    final String filePath = '${dir.path}/recu_paiement_$paiementId.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }

  // ─── URL brute (conservée pour usage éventuel interne) ──────────────────────
  String getRecuUrl(int ecoleId, int paiementId) {
    return ApiService.getRecuUrl(ecoleId, paiementId);
  }
}