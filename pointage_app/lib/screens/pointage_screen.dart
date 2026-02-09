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
  bool _repas = true; // indemnité repas cochée par défaut

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

  Future<void> _pointer({TimeEntryType type = TimeEntryType.travail}) async {
    if (_selectedEmployee == null) return;

    final now = DateTime.now();

    if (_activeEntry != null) {
      // Départ : on complète le pointage en cours
      final updated = _activeEntry!.copyWith(heureDepart: now);
      await _db.updateTimeEntry(updated);
      setState(() => _activeEntry = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Depart enregistre pour ${_selectedEmployee!.nomComplet} a ${DateFormat('HH:mm').format(now)}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Arrivée : nouveau pointage
      final entry = TimeEntry(
        employeeId: _selectedEmployee!.id!,
        date: DateTime(now.year, now.month, now.day),
        heureArrivee: now,
        type: type,
        repas: _repas,
      );
      await _db.insertTimeEntry(entry);
      final active = await _db.getActiveEntry(_selectedEmployee!.id!);
      setState(() => _activeEntry = active);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Arrivee enregistree pour ${_selectedEmployee!.nomComplet} a ${DateFormat('HH:mm').format(now)} (${type.label})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _enregistrerAbsence(TimeEntryType type) async {
    if (_selectedEmployee == null) return;

    String? note;
    if (type == TimeEntryType.autreAbsence) {
      note = await _showNoteDialog();
      if (note == null) return;
    }

    final now = DateTime.now();
    final entry = TimeEntry(
      employeeId: _selectedEmployee!.id!,
      date: DateTime(now.year, now.month, now.day),
      type: type,
      note: note,
    );
    await _db.insertTimeEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.label} enregistre pour ${_selectedEmployee!.nomComplet}'),
        ),
      );
    }
  }

  Future<String?> _showNoteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif de l\'absence'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Saisir le motif...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
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
                'Aucun employe enregistre',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez des employes depuis l\'onglet "Employes" pour commencer.',
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
          // Selection employe
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selectionner un employe',
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

          const SizedBox(height: 16),

          if (_selectedEmployee != null) ...[
            // Options de pointage
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _repas,
                      onChanged: (v) => setState(() => _repas = v ?? true),
                    ),
                    const Text('Indemnite repas'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Statut actuel
                      if (_activeEntry != null) ...[
                        const Icon(Icons.access_time, size: 40, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          'En poste depuis ${DateFormat('HH:mm').format(_activeEntry!.heureArrivee!)} (${_activeEntry!.type.label})',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Boutons de pointage travail
                      if (_activeEntry == null) ...[
                        // Pointage normal
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: ElevatedButton(
                            onPressed: () => _pointer(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 8,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: 44),
                                SizedBox(height: 8),
                                Text('ARRIVEE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Options : nuit, ferie, dimanche
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.nightlight, size: 18),
                              label: const Text('Nuit'),
                              onPressed: () => _pointer(type: TimeEntryType.travailNuit),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.flag, size: 18),
                              label: const Text('Jour ferie'),
                              onPressed: () => _pointer(type: TimeEntryType.travailFerie),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.weekend, size: 18),
                              label: const Text('Dimanche'),
                              onPressed: () => _pointer(type: TimeEntryType.travailDimanche),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Bouton depart
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: ElevatedButton(
                            onPressed: () => _pointer(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 8,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 44),
                                SizedBox(height: 8),
                                Text('DEPART', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Absences
                      const Text('Ou enregistrer une absence :', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _absenceChip(TimeEntryType.congePaye, Icons.beach_access),
                          _absenceChip(TimeEntryType.congeIntemperies, Icons.thunderstorm),
                          _absenceChip(TimeEntryType.congeSansSolde, Icons.money_off),
                          _absenceChip(TimeEntryType.maternite, Icons.child_friendly),
                          _absenceChip(TimeEntryType.accidentTravail, Icons.warning),
                          _absenceChip(TimeEntryType.maladieNonPro, Icons.local_hospital),
                          _absenceChip(TimeEntryType.maladiePro, Icons.health_and_safety),
                          _absenceChip(TimeEntryType.autreAbsence, Icons.event_busy),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _absenceChip(TimeEntryType type, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(type.label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _enregistrerAbsence(type),
    );
  }
}
