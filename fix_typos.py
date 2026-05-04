import os
import glob

replacements = {
    '"tudiant"': '"Étudiant"',
    "'tudiant'": "'Étudiant'",
    '"tudiant : ': '"Étudiant : ',
    '// Champs tudiant': '// Champs étudiant',
    '"Compltez ': '"Complétez ',
    '"Gnrez ': '"Générez ',
    '"Gnrer ': '"Générer ',
    '"gnr ': '"généré ',
    '"gnr"': '"généré"',
    '"Rgnrer"': '"Régénérer"',
    "'Rgnrer'": "'Régénérer'",
    '"Utilis"': '"Utilisé"',
    '"Cr le ': '"Créé le ',
    "'Code copi !'": "'Code copié !'",
    '"Code copi !"': '"Code copié !"',
    '"Code copi ': '"Code copié ',
    "'Code copi ": "'Code copié ",
    "'Code rgnr ": "'Code régénéré ",
    '"Code rgnr ': '"Code régénéré ',
    ' succs"': ' succès"',
    " succs'": " succès'",
    '"cole"': '"école"',
    ' votre cole"': ' votre école"',
    ' votre cole,': ' votre école,',
    ' d\'une cole': ' d\'une école',
    ' des coles': ' des écoles',
    '"Allez dans l\'onglet \"Gnrer\"': '"Allez dans l\'onglet \"Générer\"',
    '"Aucun code gnr"': '"Aucun code généré"',
    '"Code gnr pour ': '"Code généré pour ',
    '\"Gnrer un code d\'invitation\"': '\"Générer un code d\'invitation\"',
    '\"Comment a fonctionne ?\"': '\"Comment ça fonctionne ?\"',
    ' tre rutilis': ' être réutilisé'
}

lib_dir = r"d:\Dossier\MemoSchool\Front-end\appliformulaire\lib"
files = glob.glob(os.path.join(lib_dir, "**/*.dart"), recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {os.path.basename(file)}")
