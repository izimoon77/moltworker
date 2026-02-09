# Pointage App

Application Flutter de pointage des heures employes avec export CSV au format exact attendu par le cabinet comptable.

## Fonctionnalites

- **Pointage** : Arrivee/Depart en un tap (travail normal, nuit, ferie, dimanche)
- **Gestion employes** : Ajout, modification, activation/desactivation, salaire, mutuelle
- **Absences** : Conge paye, intemperies, sans solde, maternite, accident de travail, maladie pro/non pro, autre
- **Indemnite repas** : Compteur automatique par jour travaille
- **Historique** : Consultation et filtrage des pointages
- **Export CSV** : Format identique au tableau "Variables de Paie" du cabinet comptable
- **Reglages** : Nom de la societe pour l'en-tete du CSV

## Format de l'export CSV

Le CSV genere reproduit exactement le format du tableau "VARIABLE DE PAIE" :

- **Format transpose** : lignes = variables, colonnes = un salarie chacune
- **Separateur** : point-virgule (;)
- **Nom du fichier** : `VARIABLE_DE_PAIE_MOIS_ANNEE.csv`

### Variables exportees

| Ligne | Variable |
|---|---|
| 1 | NOM DE LA SOCIETE |
| 2 | mois : Mois Annee |
| 3 | Nom et prenom du salarie |
| 4 | Montant du salaire (SMIC ou montant brut) |
| 5 | Total des heures travaillees dans le mois |
| 6 | Heures Complementaires (temps partiel) |
| 7 | Heures de Nuit (22h-6h) |
| 8 | HS 25% 36eme a 43eme heure |
| 9 | HS 50% a partir de la 44eme heure |
| 10 | Heures de jour ferie |
| 11 | Heures de dimanche |
| 12 | Conges payes (du/au) |
| 13 | Conges intemperies (du/au) |
| 14 | Conges sans soldes (du/au) |
| 15 | Maternite (du/au) |
| 16 | Accident de travail (du/au) |
| 17 | Maladie non professionnelle (du/au) |
| 18 | Maladie Professionnelle (du/au) |
| 19 | Autres Absences (du/au) |
| 20 | Motif autres absences |
| 21 | Acomptes |
| 22 | Prime de Partage de la Valeur (PPV) |
| 23 | Autres primes (soumises aux charges sociales) |
| 24 | Indemnite repas (nombre) |
| 25 | Adhesion a la mutuelle (OUI/NON + date) |
| 26 | Autres variables |

## Installation

```bash
cd pointage_app
flutter pub get
flutter run
```

## Architecture

```
lib/
├── main.dart                   # Point d'entree, navigation 5 onglets
├── models/
│   ├── employee.dart           # Modele employe (matricule, salaire, mutuelle...)
│   ├── time_entry.dart         # Modele pointage (12 types)
│   └── payroll_export.dart     # Modele export paie (24 variables)
├── services/
│   ├── database_service.dart   # SQLite (employes, pointages, parametres)
│   └── export_service.dart     # Calcul paie + CSV transpose
└── screens/
    ├── pointage_screen.dart    # Ecran de pointage (arrivee/depart + absences)
    ├── employees_screen.dart   # Gestion des employes
    ├── history_screen.dart     # Historique des pointages
    ├── export_screen.dart      # Apercu et export comptable
    └── settings_screen.dart    # Parametres societe
```

## Stack technique

- **Flutter** avec Material 3
- **SQLite** (sqflite) pour le stockage local
- **CSV** pour l'export comptable (separateur ;)
- **share_plus** pour le partage du fichier CSV (email, messagerie...)
- **intl** pour le formatage des dates en francais
