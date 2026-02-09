import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _db.getEmployees(actifsOnly: false);
    setState(() {
      _employees = employees;
      _loading = false;
    });
  }

  Future<void> _showEmployeeDialog({Employee? employee}) async {
    final isNew = employee == null;
    final matriculeController =
        TextEditingController(text: employee?.matricule ?? '');
    final nomController = TextEditingController(text: employee?.nom ?? '');
    final prenomController =
        TextEditingController(text: employee?.prenom ?? '');
    final posteController = TextEditingController(text: employee?.poste ?? '');
    final tauxController = TextEditingController(
      text: employee?.tauxHoraire.toStringAsFixed(2) ?? '',
    );
    final heuresController = TextEditingController(
      text: (employee?.heuresHebdo ?? 35.0).toStringAsFixed(1),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Nouvel employé' : 'Modifier employé'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: matriculeController,
                  decoration: const InputDecoration(
                    labelText: 'Matricule *',
                    hintText: 'EMP001',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: posteController,
                  decoration: const InputDecoration(
                    labelText: 'Poste *',
                    hintText: 'Développeur, Comptable...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tauxController,
                  decoration: const InputDecoration(
                    labelText: 'Taux horaire (€) *',
                    hintText: '12.50',
                    border: OutlineInputBorder(),
                    suffixText: '€/h',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Nombre invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: heuresController,
                  decoration: const InputDecoration(
                    labelText: 'Heures hebdo contractuelles',
                    hintText: '35.0',
                    border: OutlineInputBorder(),
                    suffixText: 'h/sem',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final taux = double.parse(
        tauxController.text.replaceAll(',', '.'),
      );
      final heures = double.tryParse(
            heuresController.text.replaceAll(',', '.'),
          ) ??
          35.0;

      final newEmployee = Employee(
        id: employee?.id,
        matricule: matriculeController.text.trim(),
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        poste: posteController.text.trim(),
        tauxHoraire: taux,
        heuresHebdo: heures,
        actif: employee?.actif ?? true,
      );

      if (isNew) {
        await _db.insertEmployee(newEmployee);
      } else {
        await _db.updateEmployee(newEmployee);
      }
      await _loadEmployees();
    }
  }

  Future<void> _toggleActif(Employee employee) async {
    final updated = employee.copyWith(actif: !employee.actif);
    await _db.updateEmployee(updated);
    await _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _employees.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun employé',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Appuyez sur + pour ajouter votre premier employé.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          emp.actif ? Colors.blue : Colors.grey.shade300,
                      child: Text(
                        emp.prenom.isNotEmpty ? emp.prenom[0] : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      emp.nomComplet,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: emp.actif ? null : Colors.grey,
                        decoration:
                            emp.actif ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${emp.matricule} • ${emp.poste} • ${emp.tauxHoraire.toStringAsFixed(2)}€/h',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Modifier'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            leading: Icon(
                              emp.actif ? Icons.person_off : Icons.person,
                            ),
                            title: Text(
                              emp.actif ? 'Désactiver' : 'Réactiver',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEmployeeDialog(employee: emp);
                        } else if (value == 'toggle') {
                          _toggleActif(emp);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEmployeeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
