# BUILDTRACE

Première base frontend de BUILDTRACE.

## Contenu actuel

- Écran de bienvenue affiché tant qu'aucun compte n'a été créé.
- Écrans de création de compte et de connexion (interface de démonstration).
- Splash screen avec le logo BUILDTRACE après création du compte et aux lancements suivants si la session reste active.
- Première interface d'accueil après connexion.

## Parcours prévu

1. Aucun compte enregistré : afficher l'écran de bienvenue à chaque ouverture.
2. Création de compte réussie : ouvrir l'espace utilisateur.
3. Session active lors d'une ouverture suivante : afficher brièvement le splash screen, puis l'accueil.
4. Session terminée : afficher l'écran de connexion, sans revenir à la page de bienvenue.

## État technique

Cette étape est uniquement frontend. L'inscription et la connexion sont simulées dans le navigateur avec un profil de démonstration et un indicateur de session dans `localStorage`. Aucun mot de passe n'est enregistré. Ce mécanisme doit être remplacé par Supabase Auth avant toute mise en production.

Les boutons Google et Apple sont des emplacements d'interface : les fournisseurs OAuth seront configurés lors du branchement de Supabase Auth.

## Démarrage

Le projet est actuellement une page HTML autonome : ouvrir `index.html` dans un navigateur ou déployer le dossier comme site statique.

## Prochaines étapes

- Valider le rendu sur mobile et ordinateur.
- Brancher Supabase Auth et remplacer la simulation locale.
- Construire les écrans Recherche, Marketplace, publication, messagerie et Profil.
