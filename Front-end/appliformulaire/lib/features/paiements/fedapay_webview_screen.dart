// lib/features/paiements/fedapay_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── Enum public utilisé par paiement_screen.dart ──────────────────────────
enum FedaPayResultat { approuve, annule, enCours }

class FedaPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String titre;

  const FedaPayWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.titre = 'Paiement sécurisé',
  });

  @override
  State<FedaPayWebViewScreen> createState() => _FedaPayWebViewScreenState();
}

class _FedaPayWebViewScreenState extends State<FedaPayWebViewScreen> {
  late final WebViewController _controller;
  bool _loading     = true;
  String? _erreur;
  int _progression  = 0;
  FedaPayResultat? _resultat;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() { _loading = true; _erreur = null; });
          _detecterResultat(url);
        },
        onPageFinished: (url) {
          setState(() => _loading = false);
          _detecterResultat(url);
        },
        onProgress: (p) => setState(() => _progression = p),
        onWebResourceError: (error) {
          // Ignorer erreurs -1 et -2 (redirections normales FedaPay)
          if (error.errorCode == -1 || error.errorCode == -2) return;
          setState(() { _loading = false; _erreur = 'Erreur de chargement (${error.errorCode})'; });
        },
        onNavigationRequest: (request) {
          final url = request.url;
          if (_estUrlRetour(url)) {
            _detecterResultat(url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _estUrlRetour(String url) {
    final u = url.toLowerCase();
    return u.contains('approved') || u.contains('success') ||
           u.contains('canceled') || u.contains('declined') ||
           u.contains('callback') || u.contains('return')   ||
           u.contains('redirect');
  }

  void _detecterResultat(String url) {
    final u = url.toLowerCase();
    if (u.contains('approved') || u.contains('success')) {
      setState(() => _resultat = FedaPayResultat.approuve);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop(FedaPayResultat.approuve);
      });
    } else if (u.contains('canceled') || u.contains('cancelled') || u.contains('declined')) {
      setState(() => _resultat = FedaPayResultat.annule);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop(FedaPayResultat.annule);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.titre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmerAnnulation(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _loading
              ? LinearProgressIndicator(
                  value: _progression / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: Stack(children: [

        // ── WebView ──────────────────────────────────────────────────────
        if (_erreur == null) WebViewWidget(controller: _controller),

        // ── Erreur ───────────────────────────────────────────────────────
        if (_erreur != null)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFC62828)),
              const SizedBox(height: 16),
              Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC62828))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                onPressed: () {
                  setState(() => _erreur = null);
                  _controller.loadRequest(Uri.parse(widget.paymentUrl));
                },
              ),
            ]),
          )),

        // ── Overlay succès ───────────────────────────────────────────────
        if (_resultat == FedaPayResultat.approuve)
          Container(
            color: Colors.white.withOpacity(0.96),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 60, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 20),
              const Text('Paiement réussi !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              const Text('Votre paiement a été approuvé.', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              const Text('Fermeture en cours...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ])),
          ),

        // ── Overlay annulé ───────────────────────────────────────────────
        if (_resultat == FedaPayResultat.annule)
          Container(
            color: Colors.white.withOpacity(0.96),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: const Color(0xFFC62828).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.cancel_rounded, size: 60, color: Color(0xFFC62828)),
              ),
              const SizedBox(height: 20),
              const Text('Paiement annulé', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
              const SizedBox(height: 8),
              const Text('Le paiement a été annulé ou refusé.', style: TextStyle(color: Color(0xFF6B7280))),
            ])),
          ),
      ]),
    );
  }

  Future<void> _confirmerAnnulation() async {
    if (_resultat != null) {
      Navigator.of(context).pop(_resultat);
      return;
    }
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter le paiement ?'),
        content: const Text('Le paiement est en cours. Voulez-vous vraiment annuler ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirme == true && mounted) {
      Navigator.of(context).pop(FedaPayResultat.annule);
    }
  }
}