# Immersya – Application Mobile de Capture 3D Participative

**Immersya Mobile** est une application mobile Flutter conçue comme l'outil de terrain de la plateforme IMMERSYA.  
Elle permet aux utilisateurs de capturer le monde réel en 3D, de suivre des missions géolocalisées, de visualiser leurs contributions sur une carte interactive, et de participer à un écosystème collaboratif.


## 🚀 État du projet : MVP+ (Minimum Viable Product Plus)

L'application dépasse le stade de prototype. Elle constitue un MVP fonctionnel, robuste, avec une boucle utilisateur complète et une expérience fluide.


## ✅ Fonctionnalités Implémentées

### 1. Noyau de l'Application & Navigation
- Architecture modulaire par fonctionnalités (`lib/features`)
- Gestion d'état via `provider` (ex: `CaptureState`)
- Navigation persistante à onglets : Carte, Capture, Missions, Galerie, Profil

### 2. Carte Interactive
- Rendu performant via `flutter_map`
- Géolocalisation en temps réel (`geolocator`)
- Fond sombre (tiles CartoDB)
- Affichage dynamique de zones couvertes (coloration par état)
- Marqueur utilisateur animé (effet pulsation)

### 3. Flux de Capture Complet
- **Mode Mission** : mission acceptée → capture ciblée
- **Mode Libre** : scan libre (intérieur, avatar, objet)
- Interface caméra + HUD
- Simulation d'upload avec feedback visuel

### 4. Écosystème de Gamification
- Écran Profil : Points, Rang, Surface couverte
- Système de Missions avec récompenses et priorités
- Galerie des Scans avec statut (En traitement, Échec, Validé)
- Détail contribution : note de qualité, aperçu 3D (`model_viewer_plus`)

### 5. Paramètres et Qualité de Vie
- Écran paramètres : LiDAR, notifications, qualité
- Sauvegarde locale (`shared_preferences`)
- Permissions (caméra, GPS) gérées proprement


## 🗺️ Feuille de Route (Roadmap)

### 🔥 Priorité Haute : Production Ready

#### Backend réel
- Remplacer `MockApiService` par API REST (FastAPI ou Express)
- Endpoints : `/zones`, `/missions`, `/user/...`
- Connexion PostgreSQL + PostGIS
- Intégration HTTP (`http` ou `dio`)

#### Authentification
- Firebase Auth ou système JWT
- Écrans : Connexion, Inscription, Mot de passe oublié
- Endpoints protégés

#### Résilience réseau
- Feedback en cas d’échec réseau
- Stockage offline (`sqflite`) + upload différé


### ✨ Priorité Moyenne : Amélioration UX/UI

#### Animations
- Transitions animées, effets de Hero
- Animation d'apparition dans les listes
- Marqueurs dynamiques sur la carte

#### Capture intelligente
- `geolocator` pour photos automatiques tous les X mètres
- Intégration LiDAR (PlatformChannel vers ARKit/ARCore)


### 🌐 Priorité Basse : Extensions

#### Marketplace d'Assets
- Écrans : catalogue, recherche, détails
- Transactions via Immersya Points

#### Fonctionnalités Sociales
- Système de vote sur la qualité
- Classements hebdo/mensuels
- Notifications push (FCM)


## 🧱 Stack Technique

- **Framework** : Flutter 3.x
- **Langages** : Dart, SQL (PostgreSQL), JSON API
- **Carte** : `flutter_map`, tiles CartoDB / MapLibre
- **Modèle 3D** : `model_viewer_plus`, `.glTF`
- **Backend (à venir)** : FastAPI (Python) ou Express (Node.js)
- **Base de données** : PostgreSQL + PostGIS
- **Gestion d’état** : `provider`
- **Persistance locale** : `shared_preferences`, `sqflite`


## 📸 Aperçu Visuel (Prototype)

*(Captures à intégrer ici dans un dépôt GitHub)*


## 👥 Contribuer

1. Fork le dépôt
2. Clone localement
3. `flutter pub get`
4. Lance avec `flutter run`
5. Crée une branche et une PR



## Licence

© Immersya 2025