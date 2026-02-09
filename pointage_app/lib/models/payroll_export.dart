/// Représente les données mensuelles d'un employé pour l'export comptable.
/// Ces variables correspondent aux informations attendues par le cabinet comptable
/// pour établir les bulletins de paie.
class PayrollExport {
  final String matricule;
  final String nom;
  final String prenom;
  final String poste;
  final int mois;
  final int annee;
  final double heuresNormales;
  final double heuresSup25; // heures supplémentaires majorées à 25%
  final double heuresSup50; // heures supplémentaires majorées à 50%
  final double totalHeures;
  final int joursTravailles;
  final int joursConges;
  final int joursMaladie;
  final int joursAbsence;
  final double tauxHoraire;
  final double salaireBrutEstime;

  PayrollExport({
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.poste,
    required this.mois,
    required this.annee,
    required this.heuresNormales,
    required this.heuresSup25,
    required this.heuresSup50,
    required this.totalHeures,
    required this.joursTravailles,
    required this.joursConges,
    required this.joursMaladie,
    required this.joursAbsence,
    required this.tauxHoraire,
    required this.salaireBrutEstime,
  });

  /// Période formatée (ex: "01/2026")
  String get periode => '${mois.toString().padLeft(2, '0')}/$annee';

  /// Ligne CSV pour export
  List<String> toCsvRow() {
    return [
      matricule,
      nom,
      prenom,
      poste,
      periode,
      heuresNormales.toStringAsFixed(2),
      heuresSup25.toStringAsFixed(2),
      heuresSup50.toStringAsFixed(2),
      totalHeures.toStringAsFixed(2),
      joursTravailles.toString(),
      joursConges.toString(),
      joursMaladie.toString(),
      joursAbsence.toString(),
      tauxHoraire.toStringAsFixed(2),
      salaireBrutEstime.toStringAsFixed(2),
    ];
  }

  /// En-têtes CSV
  static List<String> csvHeaders() {
    return [
      'Matricule',
      'Nom',
      'Prénom',
      'Poste',
      'Période',
      'Heures normales',
      'Heures sup 25%',
      'Heures sup 50%',
      'Total heures',
      'Jours travaillés',
      'Jours congés',
      'Jours maladie',
      'Jours absence',
      'Taux horaire (€)',
      'Salaire brut estimé (€)',
    ];
  }
}
