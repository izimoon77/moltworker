import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/time_entry.dart';
import '../models/payroll_export.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db = DatabaseService();

  /// Calcule les données de paie pour un employé sur un mois donné.
  /// Applique les règles françaises :
  /// - Heures normales : jusqu'à heuresHebdo/semaine (défaut 35h)
  /// - Heures sup 25% : de 35h à 43h/semaine
  /// - Heures sup 50% : au-delà de 43h/semaine
  Future<PayrollExport> calculatePayroll(
    Employee employee,
    int year,
    int month,
  ) async {
    final entries = await _db.getMonthlyEntries(employee.id!, year, month);

    double totalHeuresTravaillees = 0;
    int joursTravailles = 0;
    int joursConges = 0;
    int joursMaladie = 0;
    int joursAbsence = 0;

    // Regrouper par jour pour compter les jours
    final parJour = <String, List<TimeEntry>>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
      parJour.putIfAbsent(dateKey, () => []).add(entry);
    }

    for (final dayEntries in parJour.values) {
      // Vérifier le type principal du jour
      final types = dayEntries.map((e) => e.type).toSet();
      if (types.contains(TimeEntryType.conge)) {
        joursConges++;
      } else if (types.contains(TimeEntryType.maladie)) {
        joursMaladie++;
      } else if (types.contains(TimeEntryType.absence)) {
        joursAbsence++;
      } else {
        joursTravailles++;
        for (final entry in dayEntries) {
          totalHeuresTravaillees += entry.dureeHeures;
        }
      }
    }

    // Calcul heures normales vs supplémentaires
    // Basé sur le mensuel : heuresHebdo * (52/12) ≈ heures mensuelles normales
    final heuresMensuellesNormales = employee.heuresHebdo * 52 / 12;
    // Seuil heures sup 50% : 43h/semaine * 52/12
    final seuilSup50 = 43.0 * 52 / 12;

    double heuresNormales;
    double heuresSup25;
    double heuresSup50;

    if (totalHeuresTravaillees <= heuresMensuellesNormales) {
      heuresNormales = totalHeuresTravaillees;
      heuresSup25 = 0;
      heuresSup50 = 0;
    } else if (totalHeuresTravaillees <= seuilSup50) {
      heuresNormales = heuresMensuellesNormales;
      heuresSup25 = totalHeuresTravaillees - heuresMensuellesNormales;
      heuresSup50 = 0;
    } else {
      heuresNormales = heuresMensuellesNormales;
      heuresSup25 = seuilSup50 - heuresMensuellesNormales;
      heuresSup50 = totalHeuresTravaillees - seuilSup50;
    }

    // Estimation du salaire brut
    final salaireBrut = (heuresNormales * employee.tauxHoraire) +
        (heuresSup25 * employee.tauxHoraire * 1.25) +
        (heuresSup50 * employee.tauxHoraire * 1.50);

    return PayrollExport(
      matricule: employee.matricule,
      nom: employee.nom,
      prenom: employee.prenom,
      poste: employee.poste,
      mois: month,
      annee: year,
      heuresNormales: heuresNormales,
      heuresSup25: heuresSup25,
      heuresSup50: heuresSup50,
      totalHeures: totalHeuresTravaillees,
      joursTravailles: joursTravailles,
      joursConges: joursConges,
      joursMaladie: joursMaladie,
      joursAbsence: joursAbsence,
      tauxHoraire: employee.tauxHoraire,
      salaireBrutEstime: salaireBrut,
    );
  }

  /// Génère un fichier CSV pour tous les employés sur un mois donné.
  /// Retourne le chemin du fichier généré.
  Future<String> exportMonthlyCsv(int year, int month) async {
    final employees = await _db.getEmployees();
    final exports = <PayrollExport>[];

    for (final employee in employees) {
      final payroll = await calculatePayroll(employee, year, month);
      exports.add(payroll);
    }

    final rows = <List<String>>[
      PayrollExport.csvHeaders(),
      ...exports.map((e) => e.toCsvRow()),
    ];

    final csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final monthStr = month.toString().padLeft(2, '0');
    final fileName = 'export_paie_${year}_$monthStr.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }

  /// Génère un export pour un seul employé
  Future<String> exportEmployeeCsv(
    Employee employee,
    int year,
    int month,
  ) async {
    final payroll = await calculatePayroll(employee, year, month);

    final rows = <List<String>>[
      PayrollExport.csvHeaders(),
      payroll.toCsvRow(),
    ];

    final csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final monthStr = month.toString().padLeft(2, '0');
    final fileName =
        'export_paie_${employee.matricule}_${year}_$monthStr.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }
}
