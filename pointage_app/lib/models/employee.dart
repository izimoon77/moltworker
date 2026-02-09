class Employee {
  final int? id;
  final String matricule;
  final String nom;
  final String prenom;
  final String poste;
  final double tauxHoraire;
  final double heuresHebdo; // heures contractuelles par semaine (ex: 35)
  final String salaire; // "SMIC" ou montant brut
  final bool mutuelle;
  final String? dateMutuelle;
  final bool actif;

  Employee({
    this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.poste,
    required this.tauxHoraire,
    this.heuresHebdo = 35.0,
    this.salaire = 'SMIC',
    this.mutuelle = false,
    this.dateMutuelle,
    this.actif = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'poste': poste,
      'taux_horaire': tauxHoraire,
      'heures_hebdo': heuresHebdo,
      'salaire': salaire,
      'mutuelle': mutuelle ? 1 : 0,
      'date_mutuelle': dateMutuelle,
      'actif': actif ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      matricule: map['matricule'] as String,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      poste: map['poste'] as String,
      tauxHoraire: (map['taux_horaire'] as num).toDouble(),
      heuresHebdo: (map['heures_hebdo'] as num?)?.toDouble() ?? 35.0,
      salaire: map['salaire'] as String? ?? 'SMIC',
      mutuelle: (map['mutuelle'] as int?) == 1,
      dateMutuelle: map['date_mutuelle'] as String?,
      actif: (map['actif'] as int?) == 1,
    );
  }

  Employee copyWith({
    int? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? poste,
    double? tauxHoraire,
    double? heuresHebdo,
    String? salaire,
    bool? mutuelle,
    String? dateMutuelle,
    bool? actif,
  }) {
    return Employee(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      poste: poste ?? this.poste,
      tauxHoraire: tauxHoraire ?? this.tauxHoraire,
      heuresHebdo: heuresHebdo ?? this.heuresHebdo,
      salaire: salaire ?? this.salaire,
      mutuelle: mutuelle ?? this.mutuelle,
      dateMutuelle: dateMutuelle ?? this.dateMutuelle,
      actif: actif ?? this.actif,
    );
  }

  String get nomComplet => '$prenom $nom';

  String get mutuelleLine {
    if (!mutuelle) return 'NON';
    return 'OUI${dateMutuelle != null ? ' - $dateMutuelle' : ''}';
  }
}
