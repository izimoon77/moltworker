enum TimeEntryType {
  travail,
  travailNuit,       // heures de nuit 22h-6h
  travailFerie,      // jour férié
  travailDimanche,   // dimanche
  congePaye,
  congeIntemperies,
  congeSansSolde,
  maternite,
  accidentTravail,
  maladieNonPro,
  maladiePro,
  autreAbsence,
}

extension TimeEntryTypeLabel on TimeEntryType {
  String get label => switch (this) {
    TimeEntryType.travail => 'Travail',
    TimeEntryType.travailNuit => 'Travail de nuit',
    TimeEntryType.travailFerie => 'Jour férié',
    TimeEntryType.travailDimanche => 'Dimanche',
    TimeEntryType.congePaye => 'Congé payé',
    TimeEntryType.congeIntemperies => 'Congé intempéries',
    TimeEntryType.congeSansSolde => 'Congé sans solde',
    TimeEntryType.maternite => 'Maternité',
    TimeEntryType.accidentTravail => 'Accident de travail',
    TimeEntryType.maladieNonPro => 'Maladie non pro.',
    TimeEntryType.maladiePro => 'Maladie pro.',
    TimeEntryType.autreAbsence => 'Autre absence',
  };

  bool get estTravail => switch (this) {
    TimeEntryType.travail ||
    TimeEntryType.travailNuit ||
    TimeEntryType.travailFerie ||
    TimeEntryType.travailDimanche => true,
    _ => false,
  };

  bool get estAbsence => !estTravail;
}

class TimeEntry {
  final int? id;
  final int employeeId;
  final DateTime date;
  final DateTime? heureArrivee;
  final DateTime? heureDepart;
  final TimeEntryType type;
  final String? note;
  final bool repas; // indemnité repas pour ce jour

  TimeEntry({
    this.id,
    required this.employeeId,
    required this.date,
    this.heureArrivee,
    this.heureDepart,
    this.type = TimeEntryType.travail,
    this.note,
    this.repas = false,
  });

  /// Durée travaillée en heures (décimales)
  double get dureeHeures {
    if (heureArrivee == null || heureDepart == null) return 0.0;
    final diff = heureDepart!.difference(heureArrivee!);
    return diff.inMinutes / 60.0;
  }

  /// Vérifie si le pointage est en cours (arrivée sans départ)
  bool get estEnCours => heureArrivee != null && heureDepart == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String().substring(0, 10),
      'heure_arrivee': heureArrivee?.toIso8601String(),
      'heure_depart': heureDepart?.toIso8601String(),
      'type': type.name,
      'note': note,
      'repas': repas ? 1 : 0,
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      date: DateTime.parse(map['date'] as String),
      heureArrivee: map['heure_arrivee'] != null
          ? DateTime.parse(map['heure_arrivee'] as String)
          : null,
      heureDepart: map['heure_depart'] != null
          ? DateTime.parse(map['heure_depart'] as String)
          : null,
      type: TimeEntryType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'travail'),
        orElse: () => TimeEntryType.travail,
      ),
      note: map['note'] as String?,
      repas: (map['repas'] as int?) == 1,
    );
  }

  TimeEntry copyWith({
    int? id,
    int? employeeId,
    DateTime? date,
    DateTime? heureArrivee,
    DateTime? heureDepart,
    TimeEntryType? type,
    String? note,
    bool? repas,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      heureArrivee: heureArrivee ?? this.heureArrivee,
      heureDepart: heureDepart ?? this.heureDepart,
      type: type ?? this.type,
      note: note ?? this.note,
      repas: repas ?? this.repas,
    );
  }
}
