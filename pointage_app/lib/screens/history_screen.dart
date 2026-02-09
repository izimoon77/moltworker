import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/time_entry.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  List<TimeEntry> _entries = [];
  bool _loading = true;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final employees = await _db.getEmployees();
    final entries = await _db.getRecentEntries();
    setState(() {
      _employees = employees;
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _filterByEmployee(Employee? employee) async {
    setState(() {
      _selectedEmployee = employee;
      _loading = true;
    });
    final entries = await _db.getRecentEntries(
      employeeId: employee?.id,
      limit: 100,
    );
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _getEmployeeName(int employeeId) {
    final emp = _employees.where((e) => e.id == employeeId).firstOrNull;
    return emp?.nomComplet ?? 'Inconnu';
  }

  String _typeLabel(TimeEntryType type) {
    return switch (type) {
      TimeEntryType.travail => 'Travail',
      TimeEntryType.conge => 'Congé',
      TimeEntryType.maladie => 'Maladie',
      TimeEntryType.absence => 'Absence',
    };
  }

  Color _typeColor(TimeEntryType type) {
    return switch (type) {
      TimeEntryType.travail => Colors.green,
      TimeEntryType.conge => Colors.blue,
      TimeEntryType.maladie => Colors.red,
      TimeEntryType.absence => Colors.orange,
    };
  }

  IconData _typeIcon(TimeEntryType type) {
    return switch (type) {
      TimeEntryType.travail => Icons.work,
      TimeEntryType.conge => Icons.beach_access,
      TimeEntryType.maladie => Icons.local_hospital,
      TimeEntryType.absence => Icons.event_busy,
    };
  }

  Future<void> _deleteEntry(TimeEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le pointage ?'),
        content: Text(
          'Pointage du ${_dateFormat.format(entry.date)} pour ${_getEmployeeName(entry.employeeId)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteTimeEntry(entry.id!);
      await _filterByEmployee(_selectedEmployee);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtre par employé
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<Employee?>(
            value: _selectedEmployee,
            decoration: const InputDecoration(
              labelText: 'Filtrer par employé',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              const DropdownMenuItem<Employee?>(
                value: null,
                child: Text('Tous les employés'),
              ),
              ..._employees.map((e) {
                return DropdownMenuItem<Employee?>(
                  value: e,
                  child: Text(e.nomComplet),
                );
              }),
            ],
            onChanged: (employee) => _filterByEmployee(employee),
          ),
        ),

        // Liste des pointages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun pointage trouvé',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final heures = entry.dureeHeures;

                        return Dismissible(
                          key: Key('entry_${entry.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteEntry(entry);
                            return false;
                          },
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _typeColor(entry.type),
                                child: Icon(
                                  _typeIcon(entry.type),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${_getEmployeeName(entry.employeeId)} - ${_dateFormat.format(entry.date)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: entry.type == TimeEntryType.travail
                                  ? Text(
                                      '${entry.heureArrivee != null ? _timeFormat.format(entry.heureArrivee!) : '?'}'
                                      ' → '
                                      '${entry.heureDepart != null ? _timeFormat.format(entry.heureDepart!) : 'en cours'}'
                                      '${heures > 0 ? ' (${heures.toStringAsFixed(1)}h)' : ''}',
                                    )
                                  : Text(_typeLabel(entry.type)),
                              trailing: entry.estEnCours
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'EN COURS',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
