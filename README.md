# Immersya Mobile – Application Mobile de Capture 3D Participative

**Immersya Mobile** est une application mobile Flutter conçue comme l'outil de terrain de la plateforme IMMERSYA.  
Elle permet aux utilisateurs de capturer le monde réel en 3D, de suivre des missions géolocalisées, de visualiser leurs contributions sur une carte interactive, et de participer à un écosystème collaboratif et ludique.

## 🚀 État du projet : MVP+ (Minimum Viable Product Plus)

L'application a dépassé le stade de prototype. Elle constitue un MVP fonctionnel et robuste, avec une boucle utilisateur complète, une interface fluide, et des fonctionnalités avancées de gamification et de personnalisation.

## ✅ Fonctionnalités Implémentées

### 1. Noyau de l'Application & Navigation
-   Architecture modulaire par fonctionnalités (`lib/features`).
-   Gestion d'état via `provider` (ex: `CaptureState`, `MapState`, `AuthService`).
-   Navigation persistante à onglets : Carte, Capture, Missions, Galerie, Classement, Profil.

### 2. Carte Interactive
-   Rendu performant via `flutter_map`.
-   Géolocalisation en temps réel de l'utilisateur (`geolocator`).
-   Affichage dynamique de plusieurs couches de données : zones de couverture, missions, traces GPS d'autres utilisateurs ("ghost traces"), et heatmap de contribution.
-   Système de filtres pour contrôler les couches affichées.
-   Bouton de centrage sur la position de l'utilisateur.

### 3. Système d'Authentification & Profil Utilisateur
-   Flux complet (simulé) : Inscription (avec confirmation de mot de passe) et Connexion.
-   Gestion de session utilisateur persistante via `AuthService`.
-   Écran de profil personnalisé affichant les statistiques, le rang et les badges de l'utilisateur.
-   Fonction de déconnexion sécurisée.

### 4. Écosystème de Gamification Avancé
-   **Classements dynamiques** : Classements globaux et locaux (Pays, Région, Ville) basés sur la position GPS en temps réel de l'utilisateur.
-   **Système de Badges** : Des trophées débloqués en fonction des accomplissements de l'utilisateur (points, scans, etc.).
-   **Missions** : Des objectifs géolocalisés avec des récompenses en points.
-   **Statistiques de Progression** : Suivi des points, du rang et de la surface couverte.

### 5. Flux de Capture & Galerie
-   Modes de capture : Mission guidée et Scan libre (Intérieur, Objet, Avatar).
-   Interface caméra avec HUD et simulation d'upload.
-   Galerie des scans de l'utilisateur avec statut (En traitement, Échec, Validé).
-   Détail de contribution avec note de qualité et prévisualisation 3D (via `model_viewer_plus`).

### 6. Paramètres & Qualité de Vie
-   Écran de paramètres avec options pour la capture (LiDAR, qualité).
-   Sauvegarde des préférences utilisateur via `shared_preferences`.
-   Gestion propre des permissions (caméra, GPS).

## 🗺️ Feuille de Route (Roadmap)

### 🔥 Priorité Haute : Finalisation & Production
1.  **Fiabilisation de l'Application :**
    *   **Capture Hors Ligne :** Stockage local des captures (`sqflite`) et synchronisation différée. Essentiel pour une utilisation terrain.
    *   **Correction des Prévisualisations :** Résoudre l'erreur `net::ERR_CLEARTEXT_NOT_PERMITTED` (lié à Android bloquant le trafic HTTP non sécurisé) et améliorer les options du viewer 3D.
    *   **Finalisation des Placeholders :** Remplacer les éléments temporaires de la galerie et des autres écrans.
2.  **Passage au Backend Réel :**
    *   Remplacer `MockApiService` par une API REST (FastAPI, Express...).
    *   Mettre en place la base de données (PostgreSQL + PostGIS).
    *   Intégrer une solution d'authentification réelle (Firebase Auth, JWT).

### ✨ Priorité Moyenne : Expérience Utilisateur & Social
1.  **Refonte du Design (UI/UX) :**
    *   Moderniser le design, potentiellement supprimer l'AppBar au profit d'une UI superposée.
    *   Repenser la navigation (ex: icône de profil en haut, mise en avant d'un bouton clé).
    *   Ajouter des animations et des transitions fluides.
2.  **Fonctionnalités Sociales (Équipes) :**
    *   Permettre aux utilisateurs de créer et rejoindre des équipes.
    *   Mettre en place des classements et des missions d'équipe.
3.  **Internationalisation (Multi-langue) :**
    *   Intégrer une solution de traduction pour rendre l'application accessible mondialement.

### 🌐 Priorité Basse : Nouvelles Fonctionnalités Majeures
1.  **Marketplace d'Assets :**
    *   Développer les écrans du catalogue, de la recherche et des fiches produits.
    *   Mettre en place un système de transactions (Immersya Points, etc.).
2.  **Visualisation en Réalité Augmentée (AR) :**
    *   Intégrer ARKit/ARCore pour visualiser les modèles 3D dans le monde réel.

## 🧱 Stack Technique

-   **Framework** : Flutter 3.x
-   **Langages** : Dart
-   **Carte** : `flutter_map`, `geolocator`, `geocoding`
-   **Modèle 3D** : `model_viewer_plus` (`.glTF`)
-   **Gestion d’état** : `provider`
-   **Persistance locale** : `shared_preferences`
-   **Backend (cible)** : FastAPI (Python) ou Express (Node.js) + PostgreSQL/PostGIS

## 📸 Aperçu Visuel

*(Captures d'écran à intégrer ici)*

## 👥 Contribuer

1.  Forker le dépôt.
2.  Cloner localement : `git clone ...`
3.  Installer les dépendances : `flutter pub get`
4.  Lancer l'application : `flutter run`
5.  Créer une nouvelle branche pour votre fonctionnalité et soumettre une Pull Request.

## Licence

© Immersya 2025
