import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:appliformulaire/main.dart' as app;
import 'package:appliformulaire/models/session_utilisateur.dart';
import 'package:appliformulaire/services/api_service.dart';
import 'package:appliformulaire/ecoles_selection_page.dart';

// ── Country Picker ────────────────────────────────────────────────────────────
class CountryPickerField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const CountryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CountryPickerField> createState() => _CountryPickerFieldState();
}

class _CountryPickerFieldState extends State<CountryPickerField> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filtered = [];

  static const List<Map<String, String>> _countries = [
    // Afrique de l'Ouest
    {'name': 'Bénin', 'flag': '🇧🇯', 'region': "Afrique de l'Ouest"},
    {'name': 'Burkina Faso', 'flag': '🇧🇫', 'region': "Afrique de l'Ouest"},
    {'name': 'Cabo Verde', 'flag': '🇨🇻', 'region': "Afrique de l'Ouest"},
    {'name': "Côte d'Ivoire", 'flag': '🇨🇮', 'region': "Afrique de l'Ouest"},
    {'name': 'Gambie', 'flag': '🇬🇲', 'region': "Afrique de l'Ouest"},
    {'name': 'Ghana', 'flag': '🇬🇭', 'region': "Afrique de l'Ouest"},
    {'name': 'Guinée', 'flag': '🇬🇳', 'region': "Afrique de l'Ouest"},
    {'name': 'Guinée-Bissau', 'flag': '🇬🇼', 'region': "Afrique de l'Ouest"},
    {'name': 'Libéria', 'flag': '🇱🇷', 'region': "Afrique de l'Ouest"},
    {'name': 'Mali', 'flag': '🇲🇱', 'region': "Afrique de l'Ouest"},
    {'name': 'Mauritanie', 'flag': '🇲🇷', 'region': "Afrique de l'Ouest"},
    {'name': 'Niger', 'flag': '🇳🇪', 'region': "Afrique de l'Ouest"},
    {'name': 'Nigéria', 'flag': '🇳🇬', 'region': "Afrique de l'Ouest"},
    {'name': 'Sénégal', 'flag': '🇸🇳', 'region': "Afrique de l'Ouest"},
    {'name': 'Sierra Leone', 'flag': '🇸🇱', 'region': "Afrique de l'Ouest"},
    {'name': 'Togo', 'flag': '🇹🇬', 'region': "Afrique de l'Ouest"},
    // Afrique du Nord
    {'name': 'Algérie', 'flag': '🇩🇿', 'region': 'Afrique du Nord'},
    {'name': 'Égypte', 'flag': '🇪🇬', 'region': 'Afrique du Nord'},
    {'name': 'Libye', 'flag': '🇱🇾', 'region': 'Afrique du Nord'},
    {'name': 'Maroc', 'flag': '🇲🇦', 'region': 'Afrique du Nord'},
    {'name': 'Soudan', 'flag': '🇸🇩', 'region': 'Afrique du Nord'},
    {'name': 'Tunisie', 'flag': '🇹🇳', 'region': 'Afrique du Nord'},
    // Afrique centrale
    {'name': 'Angola', 'flag': '🇦🇴', 'region': 'Afrique centrale'},
    {'name': 'Cameroun', 'flag': '🇨🇲', 'region': 'Afrique centrale'},
    {'name': 'Centrafrique', 'flag': '🇨🇫', 'region': 'Afrique centrale'},
    {'name': 'Congo', 'flag': '🇨🇬', 'region': 'Afrique centrale'},
    {'name': 'Congo (RDC)', 'flag': '🇨🇩', 'region': 'Afrique centrale'},
    {'name': 'Gabon', 'flag': '🇬🇦', 'region': 'Afrique centrale'},
    {'name': 'Guinée équatoriale', 'flag': '🇬🇶', 'region': 'Afrique centrale'},
    {'name': 'São Tomé-et-Príncipe', 'flag': '🇸🇹', 'region': 'Afrique centrale'},
    {'name': 'Tchad', 'flag': '🇹🇩', 'region': 'Afrique centrale'},
    // Afrique de l'Est
    {'name': 'Burundi', 'flag': '🇧🇮', 'region': "Afrique de l'Est"},
    {'name': 'Comores', 'flag': '🇰🇲', 'region': "Afrique de l'Est"},
    {'name': 'Djibouti', 'flag': '🇩🇯', 'region': "Afrique de l'Est"},
    {'name': 'Érythrée', 'flag': '🇪🇷', 'region': "Afrique de l'Est"},
    {'name': 'Éthiopie', 'flag': '🇪🇹', 'region': "Afrique de l'Est"},
    {'name': 'Kenya', 'flag': '🇰🇪', 'region': "Afrique de l'Est"},
    {'name': 'Madagascar', 'flag': '🇲🇬', 'region': "Afrique de l'Est"},
    {'name': 'Malawi', 'flag': '🇲🇼', 'region': "Afrique de l'Est"},
    {'name': 'Maurice', 'flag': '🇲🇺', 'region': "Afrique de l'Est"},
    {'name': 'Mozambique', 'flag': '🇲🇿', 'region': "Afrique de l'Est"},
    {'name': 'Ouganda', 'flag': '🇺🇬', 'region': "Afrique de l'Est"},
    {'name': 'Rwanda', 'flag': '🇷🇼', 'region': "Afrique de l'Est"},
    {'name': 'Seychelles', 'flag': '🇸🇨', 'region': "Afrique de l'Est"},
    {'name': 'Somalie', 'flag': '🇸🇴', 'region': "Afrique de l'Est"},
    {'name': 'Soudan du Sud', 'flag': '🇸🇸', 'region': "Afrique de l'Est"},
    {'name': 'Tanzanie', 'flag': '🇹🇿', 'region': "Afrique de l'Est"},
    // Afrique australe
    {'name': 'Afrique du Sud', 'flag': '🇿🇦', 'region': 'Afrique australe'},
    {'name': 'Botswana', 'flag': '🇧🇼', 'region': 'Afrique australe'},
    {'name': 'Eswatini', 'flag': '🇸🇿', 'region': 'Afrique australe'},
    {'name': 'Lesotho', 'flag': '🇱🇸', 'region': 'Afrique australe'},
    {'name': 'Namibie', 'flag': '🇳🇦', 'region': 'Afrique australe'},
    {'name': 'Zambie', 'flag': '🇿🇲', 'region': 'Afrique australe'},
    {'name': 'Zimbabwe', 'flag': '🇿🇼', 'region': 'Afrique australe'},
    // Europe
    {'name': 'Allemagne', 'flag': '🇩🇪', 'region': 'Europe'},
    {'name': 'Autriche', 'flag': '🇦🇹', 'region': 'Europe'},
    {'name': 'Belgique', 'flag': '🇧🇪', 'region': 'Europe'},
    {'name': 'Espagne', 'flag': '🇪🇸', 'region': 'Europe'},
    {'name': 'France', 'flag': '🇫🇷', 'region': 'Europe'},
    {'name': 'Italie', 'flag': '🇮🇹', 'region': 'Europe'},
    {'name': 'Pays-Bas', 'flag': '🇳🇱', 'region': 'Europe'},
    {'name': 'Portugal', 'flag': '🇵🇹', 'region': 'Europe'},
    {'name': 'Royaume-Uni', 'flag': '🇬🇧', 'region': 'Europe'},
    {'name': 'Suisse', 'flag': '🇨🇭', 'region': 'Europe'},
    // Amériques
    {'name': 'Brésil', 'flag': '🇧🇷', 'region': 'Amériques'},
    {'name': 'Canada', 'flag': '🇨🇦', 'region': 'Amériques'},
    {'name': 'États-Unis', 'flag': '🇺🇸', 'region': 'Amériques'},
    // Asie
    {'name': 'Chine', 'flag': '🇨🇳', 'region': 'Asie'},
    {'name': 'Inde', 'flag': '🇮🇳', 'region': 'Asie'},
    {'name': 'Japon', 'flag': '🇯🇵', 'region': 'Asie'},
  ];

  static const List<String> _regionOrder = [
    "Afrique de l'Ouest",
    'Afrique du Nord',
    'Afrique centrale',
    "Afrique de l'Est",
    'Afrique australe',
    'Europe',
    'Amériques',
    'Asie',
  ];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_countries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_countries)
          : _countries
              .where((c) => c['name']!.toLowerCase().contains(q))
              .toList();
    });
  }

  List<_CountryListItem> _buildItems() {
    final items = <_CountryListItem>[];
    for (final region in _regionOrder) {
      final regionCountries =
          _filtered.where((c) => c['region'] == region).toList();
      if (regionCountries.isEmpty) continue;
      items.add(_CountryListItem(isHeader: true, region: region));
      for (final c in regionCountries) {
        items.add(_CountryListItem(isHeader: false, country: c));
      }
    }
    return items;
  }

  Future<void> _openPicker() async {
    _searchController.clear();
    _filtered = List.from(_countries);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final items = _buildItems();
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title + close
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      const Text(
                        'Choisir un pays',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (q) {
                      _filter(q);
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Aucun pays trouvé',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final item = items[i];
                            if (item.isHeader) {
                              return Container(
                                color: Colors.grey[50],
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 4),
                                child: Text(
                                  item.region!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              );
                            }
                            final country = item.country!;
                            final isSelected =
                                widget.value == country['name'];
                            return ListTile(
                              leading: Text(
                                country['flag']!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(country['name']!),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: app.AppColors.green)
                                  : null,
                              tileColor: isSelected
                                  ? app.AppColors.green
                                      .withValues(alpha: 0.06)
                                  : null,
                              onTap: () {
                                widget.onChanged(country['name']!);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value != null
        ? _countries.firstWhere(
            (c) => c['name'] == widget.value,
            orElse: () => {},
          )
        : null;

    return FormField<String>(
      initialValue: widget.value,
      validator: (_) => widget.value == null || widget.value!.isEmpty
          ? 'Ce champ est obligatoire'
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _openPicker,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pays *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: state.hasError
                            ? app.AppColors.red
                            : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: app.AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: app.AppColors.red, width: 1.2),
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: state.errorText,
                ),
                child: Row(
                  children: [
                    if (selected != null && selected.isNotEmpty) ...[
                      Text(selected['flag']!,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        selected['name']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ] else
                      Text(
                        'Sélectionner un pays',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountryListItem {
  final bool isHeader;
  final String? region;
  final Map<String, String>? country;

  const _CountryListItem({
    required this.isHeader,
    this.region,
    this.country,
  });
}

// ── Page principale CreerEcolePage ────────────────────────────────────────────
class CreerEcolePage extends StatefulWidget {
  const CreerEcolePage({super.key});

  @override
  State<CreerEcolePage> createState() => _CreerEcolePageState();
}

class _CreerEcolePageState extends State<CreerEcolePage> {
  bool _isLoading = false;

  final _nomOfficielController = TextEditingController();
  final _sigleController = TextEditingController();
  final _siteWebController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _emailPrincipalController = TextEditingController();
  final _emailSecondaireController = TextEditingController();
  final _telFixeController = TextEditingController();
  final _telMobileController = TextEditingController();
  final _nomResponsableController = TextEditingController();
  final _titreResponsableController = TextEditingController();
  final _numeroRneController = TextEditingController();
  final _descriptionCourteController = TextEditingController();
  final _descriptionCompleteController = TextEditingController();
  final _maxEtudiantsController = TextEditingController();
  final _maxEnseignantsController = TextEditingController();

  // Pays sélectionné via le picker
  String? _selectedPays;

  // Documents
  Map<String, File?> _documents = {};
  Map<String, bool> _uploading = {};

  String? _typeEtablissement;
  int _etapeActuelle = 0;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  final List<String> _typesEtablissement = [
    'Public',
    'Privé',
    'Laïc',
    'Religieux',
    'International',
  ];

  @override
  void initState() {
    super.initState();
    _documents = {
      'autorisation_fichier': null,
      'registre_commerce_fichier': null,
      'ifu_fichier': null,
      'logo_fichier': null,
      'façade_fichier': null,
      'piece_identite_fichier': null,
      'cachet_fichier': null,
    };
    _uploading = {
      'autorisation_fichier': false,
      'registre_commerce_fichier': false,
      'ifu_fichier': false,
      'logo_fichier': false,
      'façade_fichier': false,
      'piece_identite_fichier': false,
      'cachet_fichier': false,
    };
  }

  @override
  void dispose() {
    _nomOfficielController.dispose();
    _sigleController.dispose();
    _siteWebController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _emailPrincipalController.dispose();
    _emailSecondaireController.dispose();
    _telFixeController.dispose();
    _telMobileController.dispose();
    _nomResponsableController.dispose();
    _titreResponsableController.dispose();
    _numeroRneController.dispose();
    _descriptionCourteController.dispose();
    _descriptionCompleteController.dispose();
    _maxEtudiantsController.dispose();
    _maxEnseignantsController.dispose();
    super.dispose();
  }

  Future<void> _pickerFichier(String fieldName, String label) async {
    if (!mounted) return;
    setState(() => _uploading[fieldName] = true);
    try {
      final FilePicker picker = FilePicker.platform;
      FilePickerResult? result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null &&
          mounted) {
        setState(() {
          _documents[fieldName] = File(result.files.single.path!);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' $label sélectionné'),
            backgroundColor: app.AppColors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: app.AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading[fieldName] = false);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKeys[_etapeActuelle].currentState!.validate()) return;

    if (_documents['autorisation_fichier'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez fournir l'autorisation d'ouverture"),
          backgroundColor: app.AppColors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'nom_officiel': _nomOfficielController.text.trim(),
        'sigle': _sigleController.text.trim(),
        'site_web': _siteWebController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'ville': _villeController.text.trim(),
        'code_postal': _codePostalController.text.trim(),
        'pays': _selectedPays ?? '',
        'email_principal': _emailPrincipalController.text.trim(),
        'email_secondaire': _emailSecondaireController.text.trim(),
        'tel_fixe': _telFixeController.text.trim(),
        'tel_mobile': _telMobileController.text.trim(),
        'nom_responsable': _nomResponsableController.text.trim(),
        'titre_responsable': _titreResponsableController.text.trim(),
        'numero_rne': _numeroRneController.text.trim(),
        'type_etablissement': _typeEtablissement ?? 'Public',
        'description_courte': _descriptionCourteController.text.trim(),
        'description_complete': _descriptionCompleteController.text.trim(),
        'max_etudiants': _maxEtudiantsController.text.trim(),
        'max_enseignants': _maxEnseignantsController.text.trim(),
      };

      await ApiService.creerEcoleAvecDocuments(data, _documents);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DemandeEnCoursPage()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data != null) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.toString();
      }
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: app.AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _etapeSuivante() {
    if (_formKeys[_etapeActuelle].currentState!.validate()) {
      setState(() => _etapeActuelle++);
    }
  }

  void _etapePrecedente() => setState(() => _etapeActuelle--);

  final List<String> _titresEtapes = [
    'Identité',
    'Localisation',
    'Contact',
    'Administration',
    'Documents',
  ];

  Widget _buildDocumentPicker(
      String label, String fieldName, IconData icon) {
    final isUploaded = _documents[fieldName] != null;
    final isLoading = _uploading[fieldName] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: app.AppColors.textMain,
              ),
            ),
            const SizedBox(width: 4),
            if (fieldName == 'autorisation_fichier')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: app.AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Obligatoire',
                  style: TextStyle(fontSize: 9, color: app.AppColors.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: isLoading ? null : () => _pickerFichier(fieldName, label),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isUploaded
                    ? app.AppColors.green
                    : Colors.grey.shade300,
                width: isUploaded ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: isUploaded
                  ? app.AppColors.green.withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : icon,
                  color: isUploaded
                      ? app.AppColors.green
                      : app.AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isUploaded
                        ? _documents[fieldName]!.path.split('/').last
                        : 'Aucun fichier sélectionné',
                    style: TextStyle(
                      color: isUploaded
                          ? app.AppColors.green
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.upload_file,
                    color: app.AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.AppColors.background,
      appBar: AppBar(
        title: const Text("Créer une école"),
        backgroundColor: app.AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Text(
                    "Étape ${_etapeActuelle + 1} sur 5 — ${_titresEtapes[_etapeActuelle]}",
                    style: const TextStyle(
                        fontSize: 13, color: app.AppColors.textSub),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _etapeActuelle
                                ? app.AppColors.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: _buildEtape(),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              decoration: BoxDecoration(
                color: app.AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_etapeActuelle > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _etapePrecedente,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: app.AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Précédent",
                          style:
                              TextStyle(color: app.AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _etapeActuelle > 0 ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : (_etapeActuelle < 4
                              ? _etapeSuivante
                              : _soumettre),
                      icon: _etapeActuelle < 4
                          ? const SizedBox.shrink()
                          : const Icon(Icons.send_rounded),
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _etapeActuelle < 4
                                  ? "Suivant"
                                  : "Soumettre la demande",
                              style: const TextStyle(fontSize: 15),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app.AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            app.AppColors.primary.withValues(alpha: 0.6),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etapeActuelle) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("Identité de l'école"),
              const SizedBox(height: 16),
              _champ("Nom officiel *", _nomOfficielController,
                  obligatoire: true),
              const SizedBox(height: 14),
              _champ("Sigle / Acronyme", _sigleController),
              const SizedBox(height: 14),
              _champ("Site web", _siteWebController,
                  hint: "https://www.example.com"),
            ],
          ),
        );

      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("Localisation"),
              const SizedBox(height: 16),
              _champ("Adresse complète *", _adresseController,
                  obligatoire: true),
              const SizedBox(height: 14),
              _champ("Ville *", _villeController, obligatoire: true),
              const SizedBox(height: 14),
              _champ("Code postal", _codePostalController,
                  clavier: TextInputType.number),
              const SizedBox(height: 14),
              //  CountryPickerField avec liste complète et recherche
              CountryPickerField(
                value: _selectedPays,
                onChanged: (pays) => setState(() => _selectedPays = pays),
              ),
            ],
          ),
        );

      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("Contact"),
              const SizedBox(height: 16),
              _champ("Email principal *", _emailPrincipalController,
                  obligatoire: true,
                  clavier: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _champ("Email secondaire", _emailSecondaireController,
                  clavier: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _champ("Téléphone fixe *", _telFixeController,
                  obligatoire: true, clavier: TextInputType.phone),
              const SizedBox(height: 14),
              _champ("Téléphone mobile", _telMobileController,
                  clavier: TextInputType.phone),
            ],
          ),
        );

      case 3:
        return Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("Administration & Légal"),
              const SizedBox(height: 16),
              _champ("Nom du responsable *", _nomResponsableController,
                  obligatoire: true),
              const SizedBox(height: 14),
              _champ(
                  "Titre du responsable *", _titreResponsableController,
                  obligatoire: true, hint: "ex: Directeur, Proviseur"),
              const SizedBox(height: 14),
              _champ("Numéro d'enregistrement", _numeroRneController),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _typeEtablissement,
                decoration: _deco("Type d'établissement *"),
                hint: const Text("Choisissez le type"),
                isExpanded: true,
                items: _typesEtablissement
                    .map((t) => DropdownMenuItem<String>(
                        value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _typeEtablissement = v),
                validator: (v) => v == null
                    ? "Veuillez choisir le type d'établissement"
                    : null,
              ),
            ],
          ),
        );

      case 4:
        return Form(
          key: _formKeys[4],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("Documents Justificatifs"),
              const SizedBox(height: 16),
              _buildDocumentPicker(
                "Autorisation d'ouverture / Agrément",
                'autorisation_fichier',
                Icons.description,
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                'Registre de commerce',
                'registre_commerce_fichier',
                Icons.business,
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker('IFU', 'ifu_fichier', Icons.receipt),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                "Logo de l'établissement",
                'logo_fichier',
                Icons.image,
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                "Photo de façade de l'école",
                'façade_fichier',
                Icons.photo_camera,
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                "Pièce d'identité du responsable",
                'piece_identite_fichier',
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildDocumentPicker(
                'Cachet / Document officiel signé',
                'cachet_fichier',
                Icons.security,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _titreSection(String titre) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: app.AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: app.AppColors.primary,
        ),
      ),
    );
  }

  Widget _champ(
    String label,
    TextEditingController controller, {
    bool obligatoire = false,
    String? hint,
    TextInputType clavier = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: clavier,
      decoration: _deco(label, hint: hint),
      validator: obligatoire
          ? (v) => v == null || v.trim().isEmpty
              ? "Ce champ est obligatoire"
              : null
          : null,
    );
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: app.AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: app.AppColors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: app.AppColors.red, width: 2),
      ),
    );
  }
}

// ── Page d'attente de validation ──────────────────────────────────────────────
//  CORRECTION PRINCIPALE : déconnexion → redirige vers app.Connexion (main.dart)
//    et NON vers une ConnexionPage locale dupliquée.
class DemandeEnCoursPage extends StatelessWidget {
  const DemandeEnCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 80,
                  color: app.AppColors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Votre demande d'ouverture de création d'une école est en cours de vérification par le super admin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: app.AppColors.textMain,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Vous recevrez une notification prochainement.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: app.AppColors.textSub),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Revenir à l'accueil"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EcolesSelectionPage()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Se déconnecter"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: app.AppColors.red,
                      side: const BorderSide(color: app.AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      //  CORRECTION : vider la session puis aller vers
                      //    la VRAIE page Connexion définie dans main.dart
                      SessionUtilisateur().vider();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          // app.Connexion = la page de connexion de main.dart
                          builder: (_) => const app.Connexion(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}