// lib/features/profil/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:appliformulaire/services/profil_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ancienMdpCtrl = TextEditingController();
  final _nouveauMdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();

  bool _chargement = false;
  bool _voirAncien = false;
  bool _voirNouveau = false;
  bool _voirConfirm = false;

  static const Color _bleuPrimaire = Color(0xFF3D5AF1);

  @override
  void dispose() {
    _ancienMdpCtrl.dispose();
    _nouveauMdpCtrl.dispose();
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _changerMotDePasse() async {
    // Fermer le clavier avant de traiter
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    try {
      await ProfilService.changePassword(
        currentPassword: _ancienMdpCtrl.text,
        newPassword: _nouveauMdpCtrl.text,
        newPasswordConfirmation: _confirmMdpCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Mot de passe modifié avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Retourner à l'écran précédent après succès
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.toString().replaceAll('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Widget _buildChampMdp({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A6A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: _bleuPrimaire, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[500],
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E4FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _bleuPrimaire, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Important : permet au clavier de pousser le contenu vers le haut
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _bleuPrimaire,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Modifier le mot de passe',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: _bleuPrimaire, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Le mot de passe doit contenir au moins 8 caractères.',
                          style: TextStyle(fontSize: 13, color: _bleuPrimaire),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card formulaire
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildChampMdp(
                        controller: _ancienMdpCtrl,
                        label: 'Mot de passe actuel',
                        hint: 'Votre mot de passe actuel',
                        visible: _voirAncien,
                        onToggle: () => setState(() => _voirAncien = !_voirAncien),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
                      ),
                      _buildChampMdp(
                        controller: _nouveauMdpCtrl,
                        label: 'Nouveau mot de passe',
                        hint: 'Minimum 8 caractères',
                        visible: _voirNouveau,
                        onToggle: () => setState(() => _voirNouveau = !_voirNouveau),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ce champ est requis';
                          if (v.length < 8) return 'Minimum 8 caractères';
                          if (v == _ancienMdpCtrl.text) {
                            return 'Le nouveau mot de passe doit être différent';
                          }
                          return null;
                        },
                      ),
                      _buildChampMdp(
                        controller: _confirmMdpCtrl,
                        label: 'Confirmer le mot de passe',
                        hint: 'Répétez le nouveau mot de passe',
                        visible: _voirConfirm,
                        onToggle: () => setState(() => _voirConfirm = !_voirConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ce champ est requis';
                          if (v != _nouveauMdpCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _changerMotDePasse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bleuPrimaire,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _bleuPrimaire.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _chargement
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Modifier le mot de passe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}