import 'package:intl/intl.dart';

/// Représente la plage de dates d'une absence (du/au)
class DateRange {
  final DateTime debut;
  final DateTime fin;
  DateRange(this.debut, this.fin);

  String format() {
    final f = DateFormat('dd/MM');
    return 'du ${f.format(debut)} au ${f.format(fin)}';
  }
}

/// Représente les variables de paie mensuelles d'un employé,
/// calquées exactement sur le format attendu par le cabinet comptable.
class PayrollExport {
  final String nom;
  final String prenom;
  final String salaire; // "SMIC" ou montant
  final double totalHeures; // total heures travaillées (normales + sup + nuit)
  final double heuresComplementaires;
  final double heuresNuit; // 22h-6h
  final double heuresSup25; // HS 25% (36e à 43e heure)
  final double heuresSup50; // HS 50% (à partir de 44e heure)
  final double heuresFerie;
  final double heuresDimanche;

  // Absences avec plages de dates
  final List<DateRange> congesPayes;
  final List<DateRange> congesIntemperies;
  final List<DateRange> congesSansSolde;
  final List<DateRange> maternite;
  final List<DateRange> accidentTravail;
  final List<DateRange> maladieNonPro;
  final List<DateRange> maladiePro;
  final List<DateRange> autresAbsences;
  final String? motifAutreAbsence;

  // Primes et indemnités
  final double acomptes;
  final double ppv; // Prime de Partage de la Valeur
  final double autresPrimes;
  final int indemniteRepas; // nombre de repas
  final String mutuelle; // "OUI - date" ou "NON"
  final String? autresVariables;

  PayrollExport({
    required this.nom,
    required this.prenom,
    required this.salaire,
    required this.totalHeures,
    this.heuresComplementaires = 0,
    this.heuresNuit = 0,
    this.heuresSup25 = 0,
    this.heuresSup50 = 0,
    this.heuresFerie = 0,
    this.heuresDimanche = 0,
    this.congesPayes = const [],
    this.congesIntemperies = const [],
    this.congesSansSolde = const [],
    this.maternite = const [],
    this.accidentTravail = const [],
    this.maladieNonPro = const [],
    this.maladiePro = const [],
    this.autresAbsences = const [],
    this.motifAutreAbsence,
    this.acomptes = 0,
    this.ppv = 0,
    this.autresPrimes = 0,
    this.indemniteRepas = 0,
    this.mutuelle = 'NON',
    this.autresVariables,
  });

  String get nomComplet => '$nom $prenom';

  /// Formatte une liste de plages de dates pour le CSV
  static String _formatRanges(List<DateRange> ranges) {
    if (ranges.isEmpty) return '';
    return ranges.map((r) => r.format()).join(' / ');
  }

  /// Génère la colonne de données de cet employé (une valeur par ligne variable)
  List<String> toColumn() {
    return [
      '$prenom $nom'.toUpperCase(),
      salaire,
      totalHeures > 0 ? totalHeures.toStringAsFixed(2) : '',
      heuresComplementaires > 0
          ? heuresComplementaires.toStringAsFixed(2)
          : '',
      heuresNuit > 0 ? heuresNuit.toStringAsFixed(2) : '',
      heuresSup25 > 0 ? heuresSup25.toStringAsFixed(2) : '',
      heuresSup50 > 0 ? heuresSup50.toStringAsFixed(2) : '',
      heuresFerie > 0 ? heuresFerie.toStringAsFixed(2) : '',
      heuresDimanche > 0 ? heuresDimanche.toStringAsFixed(2) : '',
      _formatRanges(congesPayes),
      _formatRanges(congesIntemperies),
      _formatRanges(congesSansSolde),
      _formatRanges(maternite),
      _formatRanges(accidentTravail),
      _formatRanges(maladieNonPro),
      _formatRanges(maladiePro),
      _formatRanges(autresAbsences),
      motifAutreAbsence ?? '',
      acomptes > 0 ? acomptes.toStringAsFixed(2) : '',
      ppv > 0 ? ppv.toStringAsFixed(2) : '',
      autresPrimes > 0 ? autresPrimes.toStringAsFixed(2) : '',
      indemniteRepas > 0 ? indemniteRepas.toString() : '',
      mutuelle,
      autresVariables ?? '',
    ];
  }

  /// Labels des lignes (colonne de gauche du tableau)
  static List<String> rowLabels() {
    return [
      'Nom et prénom du salarié',
      'Montant du salaire (préciser si brut ou net)',
      'Total des heures travaillées dans le mois (heures normales, sup, de nuits...)',
      'Heures Complémentaires',
      'Heures de Nuit (22h-6h)',
      'HS 25% 36ème à 43ème heure',
      'HS 50% à partir de la 44ème heure',
      'Heures de jour férié (préciser si c\'est de nuit)',
      'Heures de dimanche (préciser si c\'est de nuit)',
      'Congés payés',
      'Congés intempéries',
      'Congés sans soldes',
      'Maternité',
      'Accident de travail',
      'Maladie non professionnelle',
      'Maladie Professionnelle',
      'Autres Absences',
      'Motif autres absences',
      'Acomptes',
      'Prime de Partage de la Valeur (PPV)',
      'Autres primes (soumises aux charges sociales)',
      'Indemnité repas',
      'Adhésion à la mutuelle d\'entreprise (OUI/NON + date d\'adhésion)',
      'Autres variables',
    ];
  }
}
