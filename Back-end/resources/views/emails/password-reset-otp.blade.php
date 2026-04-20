<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Réinitialisation de mot de passe</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">Réinitialisation de votre mot de passe</h2>
        
        <p>Bonjour,</p>
        
        <p>Vous avez demandé à réinitialiser votre mot de passe. Voici votre code de vérification à 6 chiffres :</p>
        
        <h1 style="font-size: 40px; letter-spacing: 10px; color: #4CAF50; text-align: center; margin: 30px 0;">
            {{ $code }}
        </h1>
        
        <p>Ce code est valide pendant <strong>15 minutes</strong>.</p>
        
        <p>Si vous n’avez pas demandé cette réinitialisation, ignorez simplement cet email.</p>
        
        <p>Cordialement,<br>
        L’équipe de votre application</p>
    </div>
</body>
</html>