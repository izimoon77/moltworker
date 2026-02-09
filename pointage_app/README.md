# Pointage App

Application Flutter de pointage des heures employés avec export des variables comptables pour le cabinet comptable.

## Fonctionnalités

- **Pointage** : Arrivée/Départ en un tap par employé
- **Gestion employés** : Ajout, modification, activation/désactivation
- **Types d'entrées** : Travail, Congé, Maladie, Absence
- **Historique** : Consultation et filtrage des pointages
- **Export CSV** : Variables prêtes pour le cabinet comptable

## Variables exportées pour la comptabilité

| Variable | Description |
|---|---|
| Matricule | Identifiant unique de l'employé |
| Nom / Prénom | Identité |
| Poste | Fonction occupée |
| Période | Mois/Année |
| Heures normales | Heures dans le cadre contractuel |
| Heures sup 25% | Heures supplémentaires majorées à 25% (35h-43h/sem) |
| Heures sup 50% | Heures supplémentaires majorées à 50% (>43h/sem) |
| Total heures | Cumul mensuel |
| Jours travaillés | Nombre de jours effectifs |
| Jours congés | Congés posés |
| Jours maladie | Arrêts maladie |
| Jours absence | Autres absences |
| Taux horaire | Taux horaire brut en € |
| Salaire brut estimé | Estimation du brut mensuel |

## Installation

```bash
cd pointage_app
flutter pub get
flutter run
```

## Architecture

```
lib/
├── main.dart                  # Point d'entrée, navigation
├── models/
│   ├── employee.dart          # Modèle employé
│   ├── time_entry.dart        # Modèle pointage
│   └── payroll_export.dart    # Modèle export paie
├── services/
│   ├── database_service.dart  # SQLite (stockage local)
│   └── export_service.dart    # Calcul paie + génération CSV
└── screens/
    ├── pointage_screen.dart   # Écran de pointage
    ├── employees_screen.dart  # Gestion des employés
    ├── history_screen.dart    # Historique des pointages
    └── export_screen.dart     # Aperçu et export comptable
```

## Stack technique

- **Flutter** avec Material 3
- **SQLite** (sqflite) pour le stockage local
- **CSV** pour l'export comptable
- **share_plus** pour le partage du fichier CSV (email, messagerie...)
