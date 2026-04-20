import 'cours_model.dart';

// Données statiques pour tester sans API
// À remplacer plus tard par les appels API Laravel

List<CoursModel> donneesCoursTest = [
  CoursModel(
    id: 1,
    titre: 'Mathématiques L3',
    description: 'Analyse, algèbre et probabilités appliquées.',
    enseignant: 'Prof. Ahouannou',
    semestre: 'L3-S1',
    credits: 4,
    salle: 'Salle A1',
    horaire: '08h00 - 10h00',
    jour: 'Lundi',
  ),
  CoursModel(
    id: 2,
    titre: 'Algorithmique',
    description: 'Structures de données et algorithmes avancés.',
    enseignant: 'Prof. Sossa',
    semestre: 'L3-S1',
    credits: 3,
    salle: 'Salle B3',
    horaire: '10h00 - 12h00',
    jour: 'Mardi',
  ),
  CoursModel(
    id: 3,
    titre: 'Base de données',
    description: 'Conception et gestion des bases de données relationnelles.',
    enseignant: 'Prof. Gbénou',
    semestre: 'L3-S1',
    credits: 3,
    salle: 'Labo Info',
    horaire: '14h00 - 16h00',
    jour: 'Mercredi',
  ),
  CoursModel(
    id: 4,
    titre: 'Réseaux informatiques',
    description: 'Protocoles réseau, TCP/IP et sécurité.',
    enseignant: 'Prof. Kpatch',
    semestre: 'L3-S2',
    credits: 4,
    salle: 'Salle C2',
    horaire: '08h00 - 10h00',
    jour: 'Jeudi',
  ),
  CoursModel(
    id: 5,
    titre: 'Génie logiciel',
    description: 'Méthodes de conception et développement logiciel.',
    enseignant: 'Prof. Dossou',
    semestre: 'L3-S2',
    credits: 3,
    salle: 'Salle A2',
    horaire: '16h00 - 18h00',
    jour: 'Vendredi',
  ),
];

List<SupportModel> donneesSupportTest = [
  SupportModel(id: 1, titre: 'Cours chapitre 1 - Maths', fichierPath: '', statut: 'valide'),
  SupportModel(id: 2, titre: 'TD Algorithmique', fichierPath: '', statut: 'valide'),
  SupportModel(id: 3, titre: 'TP Base de données', fichierPath: '', statut: 'en_attente'),
];