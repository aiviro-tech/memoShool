// lib/services/profil_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/models/session_utilisateur.dart';

class ProfilService {
  // ── 1. Récupérer le profil ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfil() async {
    final response = await ApiService.dio.get('/api/profile');
    return response.data;
  }

  // ── 2. Modifier nom, prénom, téléphone ───────────────────────────────────────
  static Future<Map<String, dynamic>> updateInfo({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await ApiService.dio.put(
      '/api/profile/update',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    if (response.data['user'] != null) {
      SessionUtilisateur().mettreAJourProfil(response.data['user']);
    }
    return response.data;
  }

  // ── 3. Upload / remplacement de la photo ─────────────────────────────────────
  static Future<Map<String, dynamic>> uploadPhoto({
    File? fichier,
    Uint8List? fichierBytes,
    required String fileName,
  }) async {
    MultipartFile multipartFile;
    if (fichierBytes != null) {
      multipartFile = MultipartFile.fromBytes(fichierBytes, filename: fileName);
    } else if (fichier != null) {
      multipartFile = await MultipartFile.fromFile(fichier.path, filename: fileName);
    } else {
      throw Exception('Aucun fichier fourni');
    }

    final formData = FormData.fromMap({'photo': multipartFile});
    final response = await ApiService.dio.post(
      '/api/profile/photo',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.data['photo_profil'] != null) {
      SessionUtilisateur().mettreAJourPhoto(response.data['photo_profil']);
    }
    return response.data;
  }

  // ── 4. Supprimer la photo de profil ──────────────────────────────────────────
  static Future<void> deletePhoto() async {
    await ApiService.dio.delete('/api/profile/photo');
    // Vide l'URL en local
    SessionUtilisateur().mettreAJourPhoto('');
  }

  // ── 5. Modifier mot de passe ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await ApiService.dio.put(
      '/api/profile/password',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );
    return response.data;
  }
}