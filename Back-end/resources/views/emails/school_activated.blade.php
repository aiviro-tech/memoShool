<!DOCTYPE html>
<html>
<head>
    <title>Votre école a été activée</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <h2>Félicitations, {{ $ecole->nom_responsable }} !</h2>
    
    <p>Nous avons le plaisir de vous annoncer que la demande de création de l'école <strong>{{ $ecole->nom_officiel }}</strong> a été acceptée par l'administration.</p>
    
    <p>Vous avez été désigné comme administrateur principal de cet établissement.</p>
    
    <div style="background-color: #f4f4f4; padding: 15px; text-align: center; margin: 20px 0;">
        <p style="margin: 0; font-size: 16px;">Voici votre code d'invitation d'administration :</p>
        <h3 style="margin: 10px 0 0 0; color: #1A237E; letter-spacing: 2px;">{{ $codeAdmin }}</h3>
    </div>
    
    <p><strong>Comment utiliser ce code ?</strong></p>
    <ol>
        <li>Connectez-vous à l'application avec votre compte utilisateur.</li>
        <li>Rendez-vous dans la section "Rejoindre une école".</li>
        <li>Saisissez ce code afin d'obtenir vos droits d'administration.</li>
    </ol>
    
    <p>Bienvenue sur ShoolShip !</p>
    <p>L'équipe technique.</p>
</body>
</html>
