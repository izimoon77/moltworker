import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/employee.dart';
import '../models/payroll_export.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final DatabaseService _db = DatabaseService();
  final ExportService _exportService = ExportService();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<Employee> _employees = [];
  List<PayrollExport> _previews = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final employees = await _db.getEmployees();
    final previews = <PayrollExport>[];

    for (final emp in employees) {
      final payroll = await _exportService.calculatePayroll(
        emp,
        _selectedYear,
        _selectedMonth,
      );
      previews.add(payroll);
    }

    setState(() {
      _employees = employees;
      _previews = previews;
      _loading = false;
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final path = await _exportService.exportMonthlyCsv(
        _selectedYear,
        _selectedMonth,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export enregistré : $path'),
            action: SnackBarAction(
              label: 'Partager',
              onPressed: () {
                Share.shareXFiles([XFile(path)],
                    text: 'Export paie ${_selectedMonth.toString().padLeft(2, '0')}/$_selectedYear');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _shareCsv() async {
    setState(() => _exporting = true);
    try {
      final path = await _exportService.exportMonthlyCsv(
        _selectedYear,
        _selectedMonth,
      );
      await Share.shareXFiles(
        [XFile(path)],
        text:
            'Export paie ${_selectedMonth.toString().padLeft(2, '0')}/$_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  String _monthName(int month) {
    return DateFormat('MMMM', 'fr_FR').format(DateTime(2024, month));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sélection de la période
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.blue),
                const SizedBox(width: 12),
                const Text('Période :', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthName(i + 1)),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      _selectedMonth = v;
                      _loadData();
                    }
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (i) {
                    final year = DateTime.now().year - 2 + i;
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      _selectedYear = v;
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Aperçu des données
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _previews.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune donnée pour cette période',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _previews.length,
                      itemBuilder: (context, index) {
                        final p = _previews[index];
                        return Card(
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              '${p.prenom} ${p.nom}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${p.totalHeures.toStringAsFixed(1)}h - ${p.salaireBrutEstime.toStringAsFixed(2)}€ brut estimé',
                            ),
                            children: [
                              _buildInfoRow('Matricule', p.matricule),
                              _buildInfoRow('Poste', p.poste),
                              _buildInfoRow('Période', p.periode),
                              const Divider(),
                              _buildInfoRow('Heures normales',
                                  '${p.heuresNormales.toStringAsFixed(2)}h'),
                              _buildInfoRow('Heures sup 25%',
                                  '${p.heuresSup25.toStringAsFixed(2)}h'),
                              _buildInfoRow('Heures sup 50%',
                                  '${p.heuresSup50.toStringAsFixed(2)}h'),
                              _buildInfoRow('Total heures',
                                  '${p.totalHeures.toStringAsFixed(2)}h',
                                  bold: true),
                              const Divider(),
                              _buildInfoRow('Jours travaillés',
                                  '${p.joursTravailles}'),
                              _buildInfoRow(
                                  'Jours congés', '${p.joursConges}'),
                              _buildInfoRow(
                                  'Jours maladie', '${p.joursMaladie}'),
                              _buildInfoRow(
                                  'Jours absence', '${p.joursAbsence}'),
                              const Divider(),
                              _buildInfoRow('Taux horaire',
                                  '${p.tauxHoraire.toStringAsFixed(2)}€/h'),
                              _buildInfoRow(
                                'Salaire brut estimé',
                                '${p.salaireBrutEstime.toStringAsFixed(2)}€',
                                bold: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Boutons d'export
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportCsv,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Enregistrer CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _exporting ? null : _shareCsv,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Envoyer au comptable'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
