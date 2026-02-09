import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/time_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pointage.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT NOT NULL UNIQUE,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        poste TEXT NOT NULL,
        taux_horaire REAL NOT NULL,
        heures_hebdo REAL NOT NULL DEFAULT 35.0,
        actif INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE time_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        heure_arrivee TEXT,
        heure_depart TEXT,
        type TEXT NOT NULL DEFAULT 'travail',
        note TEXT,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_time_entries_employee_date
      ON time_entries (employee_id, date)
    ''');
  }

  // ─── Employés ───

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap()..remove('id'));
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<List<Employee>> getEmployees({bool actifsOnly = true}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: actifsOnly ? 'actif = ?' : null,
      whereArgs: actifsOnly ? [1] : null,
      orderBy: 'nom ASC, prenom ASC',
    );
    return maps.map((map) => Employee.fromMap(map)).toList();
  }

  Future<Employee?> getEmployee(int id) async {
    final db = await database;
    final maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  // ─── Pointages ───

  Future<int> insertTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.insert('time_entries', entry.toMap()..remove('id'));
  }

  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.update(
      'time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Récupère le pointage en cours (arrivée sans départ) pour un employé
  Future<TimeEntry?> getActiveEntry(int employeeId) async {
    final db = await database;
    final maps = await db.query(
      'time_entries',
      where: 'employee_id = ? AND heure_arrivee IS NOT NULL AND heure_depart IS NULL',
      whereArgs: [employeeId],
      orderBy: 'heure_arrivee DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TimeEntry.fromMap(maps.first);
  }

  /// Récupère les pointages d'un employé pour un mois donné
  Future<List<TimeEntry>> getMonthlyEntries(
    int employeeId,
    int year,
    int month,
  ) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endDate = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final maps = await db.query(
      'time_entries',
      where: 'employee_id = ? AND date >= ? AND date < ?',
      whereArgs: [employeeId, startDate, endDate],
      orderBy: 'date ASC, heure_arrivee ASC',
    );
    return maps.map((map) => TimeEntry.fromMap(map)).toList();
  }

  /// Récupère les pointages de tous les employés pour un mois donné
  Future<Map<int, List<TimeEntry>>> getAllMonthlyEntries(
    int year,
    int month,
  ) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endDate = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final maps = await db.query(
      'time_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'employee_id ASC, date ASC, heure_arrivee ASC',
    );

    final result = <int, List<TimeEntry>>{};
    for (final map in maps) {
      final entry = TimeEntry.fromMap(map);
      result.putIfAbsent(entry.employeeId, () => []).add(entry);
    }
    return result;
  }

  /// Récupère les derniers pointages pour l'historique
  Future<List<TimeEntry>> getRecentEntries({
    int? employeeId,
    int limit = 50,
  }) async {
    final db = await database;
    final maps = await db.query(
      'time_entries',
      where: employeeId != null ? 'employee_id = ?' : null,
      whereArgs: employeeId != null ? [employeeId] : null,
      orderBy: 'date DESC, heure_arrivee DESC',
      limit: limit,
    );
    return maps.map((map) => TimeEntry.fromMap(map)).toList();
  }
}
