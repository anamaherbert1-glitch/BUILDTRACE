# BUILDTRACE

Première étape frontend : les trois écrans d'entrée de BUILDTRACE.

## Écrans implémentés

1. **Bienvenue** : photo de chantier, logo SVG, slogan, bénéfices et boutons d'inscription/connexion.
2. **Inscription** : logo, boutons Google et Apple, e-mail et mot de passe. La mise en page est optimisée pour tenir sur un écran mobile.
3. **Connexion** : thème bleu nuit, logo, boutons Google et Apple, e-mail, mot de passe et lien de récupération.

Les pictogrammes d'interface et le logo sont intégrés en SVG. Les photos utilisent une image distante.

## Règles du parcours utilisateur

- Aucun compte créé : afficher l'écran de bienvenue.
- Après création du compte et première entrée : ouvrir l'application.
- Aux ouvertures suivantes avec une session active : afficher brièvement le splash screen BUILDTRACE, puis l'accueil.
- Compte déjà créé mais session inactive : afficher directement la connexion, jamais la page de bienvenue.

## État technique et sécurité

Cette version est un prototype frontend autonome. L'authentification est encore simulée dans le navigateur. Le mot de passe de démonstration est stocké localement : **ne pas utiliser de vrai mot de passe sur cette version**.

Les boutons Google et Apple sont des éléments d'interface, pas encore des connexions OAuth fonctionnelles. Le branchement de Supabase Auth remplacera la simulation avant une mise en production réelle.

## Démarrage

Ouvrir `index.html` dans un navigateur ou déployer le dossier comme site statique.

## Étape suivante

Valider ces trois écrans sur mobile avant de développer les écrans Marketplace, publication, messagerie et Profil.
