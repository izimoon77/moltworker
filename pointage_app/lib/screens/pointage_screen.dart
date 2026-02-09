import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/time_entry.dart';
import '../services/database_service.dart';

class PointageScreen extends StatefulWidget {
  const PointageScreen({super.key});

  @override
  State<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends State<PointageScreen> {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  TimeEntry? _activeEntry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _db.getEmployees();
    setState(() {
      _employees = employees;
      _loading = false;
    });
  }

  Future<void> _selectEmployee(Employee employee) async {
    final active = await _db.getActiveEntry(employee.id!);
    setState(() {
      _selectedEmployee = employee;
      _activeEntry = active;
    });
  }

  Future<void> _pointer() async {
    if (_selectedEmployee == null) return;

    final now = DateTime.now();

    if (_activeEntry != null) {
      // Départ : on complète le pointage en cours
      final updated = _activeEntry!.copyWith(heureDepart: now);
      await _db.updateTimeEntry(updated);
      setState(() {
        _activeEntry = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Départ enregistré pour ${_selectedEmployee!.nomComplet} à ${DateFormat('HH:mm').format(now)}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Arrivée : on crée un nouveau pointage
      final entry = TimeEntry(
        employeeId: _selectedEmployee!.id!,
        date: DateTime(now.year, now.month, now.day),
        heureArrivee: now,
        type: TimeEntryType.travail,
      );
      await _db.insertTimeEntry(entry);
      final active = await _db.getActiveEntry(_selectedEmployee!.id!);
      setState(() {
        _activeEntry = active;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Arrivée enregistrée pour ${_selectedEmployee!.nomComplet} à ${DateFormat('HH:mm').format(now)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _enregistrerAbsence(TimeEntryType type) async {
    if (_selectedEmployee == null) return;

    final now = DateTime.now();
    final entry = TimeEntry(
      employeeId: _selectedEmployee!.id!,
      date: DateTime(now.year, now.month, now.day),
      type: type,
    );
    await _db.insertTimeEntry(entry);

    if (mounted) {
      final label = switch (type) {
        TimeEntryType.conge => 'Congé',
        TimeEntryType.maladie => 'Arrêt maladie',
        TimeEntryType.absence => 'Absence',
        _ => '',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label enregistré pour ${_selectedEmployee!.nomComplet}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Aucun employé enregistré',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez des employés depuis l\'onglet "Employés" pour commencer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sélection employé
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionner un employé',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Employee>(
                    value: _selectedEmployee,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text('Choisir...'),
                    items: _employees.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text('${e.nomComplet} (${e.matricule})'),
                      );
                    }).toList(),
                    onChanged: (employee) {
                      if (employee != null) _selectEmployee(employee);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton de pointage principal
          if (_selectedEmployee != null) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Statut actuel
                    if (_activeEntry != null) ...[
                      const Icon(Icons.access_time, size: 40, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        'En poste depuis ${DateFormat('HH:mm').format(_activeEntry!.heureArrivee!)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Gros bouton de pointage
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: ElevatedButton(
                        onPressed: _pointer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeEntry != null
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activeEntry != null
                                  ? Icons.logout
                                  : Icons.login,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _activeEntry != null ? 'DÉPART' : 'ARRIVÉE',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons d'absence
                    const Text(
                      'Ou enregistrer :',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.beach_access, size: 18),
                          label: const Text('Congé'),
                          onPressed: () =>
                              _enregistrerAbsence(TimeEntryType.conge),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.local_hospital, size: 18),
                          label: const Text('Maladie'),
                          onPressed: () =>
                              _enregistrerAbsence(TimeEntryType.maladie),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.event_busy, size: 18),
                          label: const Text('Absence'),
                          onPressed: () =>
                              _enregistrerAbsence(TimeEntryType.absence),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
