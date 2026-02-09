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

  /// Regroupe des jours consécutifs d'un même type d'absence en plages de dates.
  List<DateRange> _buildDateRanges(List<DateTime> dates) {
    if (dates.isEmpty) return [];
    dates.sort();
    final ranges = <DateRange>[];
    var start = dates.first;
    var end = dates.first;

    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(end).inDays <= 1) {
        end = dates[i];
      } else {
        ranges.add(DateRange(start, end));
        start = dates[i];
        end = dates[i];
      }
    }
    ranges.add(DateRange(start, end));
    return ranges;
  }

  /// Calcule les variables de paie pour un employé sur un mois donné,
  /// au format exact attendu par le cabinet comptable.
  Future<PayrollExport> calculatePayroll(
    Employee employee,
    int year,
    int month,
  ) async {
    final entries = await _db.getMonthlyEntries(employee.id!, year, month);

    double totalHeures = 0;
    double heuresNuit = 0;
    double heuresFerie = 0;
    double heuresDimanche = 0;
    int nbRepas = 0;

    // Dates par type d'absence
    final absenceDates = <TimeEntryType, List<DateTime>>{};
    String? motifAutre;

    for (final entry in entries) {
      if (entry.type.estTravail) {
        final h = entry.dureeHeures;
        totalHeures += h;

        if (entry.type == TimeEntryType.travailNuit) heuresNuit += h;
        if (entry.type == TimeEntryType.travailFerie) heuresFerie += h;
        if (entry.type == TimeEntryType.travailDimanche) heuresDimanche += h;
      } else {
        absenceDates.putIfAbsent(entry.type, () => []).add(entry.date);
        if (entry.type == TimeEntryType.autreAbsence && entry.note != null) {
          motifAutre = entry.note;
        }
      }

      if (entry.repas) nbRepas++;
    }

    // Calcul heures complémentaires et supplémentaires
    // Mensualisation : heures normales = heuresHebdo * 52/12
    final heuresMensuellesNormales = employee.heuresHebdo * 52 / 12;
    // Seuil HS 50% : 43h/semaine mensualisé
    final seuilSup50 = 43.0 * 52 / 12;

    double heuresComplementaires = 0;
    double heuresSup25 = 0;
    double heuresSup50 = 0;

    if (employee.heuresHebdo < 35) {
      // Temps partiel : heures complémentaires entre contrat et 35h
      final seuil35 = 35.0 * 52 / 12;
      if (totalHeures > heuresMensuellesNormales) {
        if (totalHeures <= seuil35) {
          heuresComplementaires = totalHeures - heuresMensuellesNormales;
        } else {
          heuresComplementaires = seuil35 - heuresMensuellesNormales;
          if (totalHeures <= seuilSup50) {
            heuresSup25 = totalHeures - seuil35;
          } else {
            heuresSup25 = seuilSup50 - seuil35;
            heuresSup50 = totalHeures - seuilSup50;
          }
        }
      }
    } else {
      // Temps plein : HS directement
      if (totalHeures > heuresMensuellesNormales) {
        if (totalHeures <= seuilSup50) {
          heuresSup25 = totalHeures - heuresMensuellesNormales;
        } else {
          heuresSup25 = seuilSup50 - heuresMensuellesNormales;
          heuresSup50 = totalHeures - seuilSup50;
        }
      }
    }

    return PayrollExport(
      nom: employee.nom,
      prenom: employee.prenom,
      salaire: employee.salaire,
      totalHeures: totalHeures,
      heuresComplementaires: heuresComplementaires,
      heuresNuit: heuresNuit,
      heuresSup25: heuresSup25,
      heuresSup50: heuresSup50,
      heuresFerie: heuresFerie,
      heuresDimanche: heuresDimanche,
      congesPayes: _buildDateRanges(
          absenceDates[TimeEntryType.congePaye] ?? []),
      congesIntemperies: _buildDateRanges(
          absenceDates[TimeEntryType.congeIntemperies] ?? []),
      congesSansSolde: _buildDateRanges(
          absenceDates[TimeEntryType.congeSansSolde] ?? []),
      maternite: _buildDateRanges(
          absenceDates[TimeEntryType.maternite] ?? []),
      accidentTravail: _buildDateRanges(
          absenceDates[TimeEntryType.accidentTravail] ?? []),
      maladieNonPro: _buildDateRanges(
          absenceDates[TimeEntryType.maladieNonPro] ?? []),
      maladiePro: _buildDateRanges(
          absenceDates[TimeEntryType.maladiePro] ?? []),
      autresAbsences: _buildDateRanges(
          absenceDates[TimeEntryType.autreAbsence] ?? []),
      motifAutreAbsence: motifAutre,
      indemniteRepas: nbRepas,
      mutuelle: employee.mutuelleLine,
    );
  }

  /// Génère un CSV au format du cabinet comptable :
  /// Lignes = variables, Colonnes = salariés (format transposé).
  /// Retourne le chemin du fichier.
  Future<String> exportMonthlyCsv(int year, int month) async {
    final employees = await _db.getEmployees();
    final exports = <PayrollExport>[];

    for (final employee in employees) {
      final payroll = await calculatePayroll(employee, year, month);
      exports.add(payroll);
    }

    // Récupérer le nom de la société
    final nomSociete =
        await _db.getSetting('nom_societe') ?? 'Ma Société';

    final monthStr = month.toString().padLeft(2, '0');
    final monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(year, month));

    // Construire le tableau transposé (lignes = variables, colonnes = salariés)
    final labels = PayrollExport.rowLabels();
    final columns = exports.map((e) => e.toColumn()).toList();

    final rows = <List<String>>[];

    // Ligne d'en-tête : nom société + mois
    rows.add([
      'NOM DE LA SOCIETE : $nomSociete',
      ...List.filled(exports.length, ''),
    ]);
    rows.add([
      '',
      ...List.filled(
          exports.length > 0 ? exports.length - 1 : 0, ''),
      if (exports.isNotEmpty) 'mois : ${monthName.capitalize()} $year',
    ]);

    // Lignes de données (une par variable)
    for (var i = 0; i < labels.length; i++) {
      final row = <String>[labels[i]];
      for (final col in columns) {
        row.add(i < col.length ? col[i] : '');
      }
      rows.add(row);
    }

    // Notes de bas de page
    rows.add([]);
    rows.add([
      'Heures complémentaires : heures effectuées par un salarié à temps partiel au-delà de la durée normale prévue par son contrat de travail.'
    ]);
    rows.add([
      'Heures supplémentaires : Heures effectuées au-delà de 35h. Elles sont majorées à 25% entre la 36ème et la 43ème heures'
    ]);
    rows.add([
      'Au-delà de la 44ème heure, les heures supplémentaires sont majorées de 50%'
    ]);
    rows.add([]);
    rows.add([
      'Maladie Non Professionnelle : Maladie qui n\'est pas causée au travail effectué par le salarié'
    ]);
    rows.add([
      'Merci de nous fournir le justificatif pour chaque arrêt de travail'
    ]);

    final csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'VARIABLE_DE_PAIE_${monthName.toUpperCase()}_$year.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
