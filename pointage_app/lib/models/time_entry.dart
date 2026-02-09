enum TimeEntryType {
  travail,
  conge,
  maladie,
  absence,
}

class TimeEntry {
  final int? id;
  final int employeeId;
  final DateTime date;
  final DateTime? heureArrivee;
  final DateTime? heureDepart;
  final TimeEntryType type;
  final String? note;

  TimeEntry({
    this.id,
    required this.employeeId,
    required this.date,
    this.heureArrivee,
    this.heureDepart,
    this.type = TimeEntryType.travail,
    this.note,
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
  }) {
    return TimeEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      heureArrivee: heureArrivee ?? this.heureArrivee,
      heureDepart: heureDepart ?? this.heureDepart,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
