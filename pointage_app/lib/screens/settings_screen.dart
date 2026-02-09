import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final _nomSocieteCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final nom = await _db.getSetting('nom_societe');
    _nomSocieteCtrl.text = nom ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _db.setSetting('nom_societe', _nomSocieteCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parametres enregistres')),
      );
    }
  }

  @override
  void dispose() {
    _nomSocieteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations societe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ces informations apparaitront sur l\'export CSV envoye au cabinet comptable.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nomSocieteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la societe',
                      hintText: 'Pianeta Pizza - Quemerais Samuel',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format de l\'export CSV',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Le CSV genere reprend exactement le format "Variables de Paie" attendu par le cabinet comptable :',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _infoTile('Lignes', 'Variables de paie (heures, absences, primes...)'),
                  _infoTile('Colonnes', 'Un salarie par colonne'),
                  _infoTile('Separateur', 'Point-virgule (;)'),
                  _infoTile('Nom du fichier', 'VARIABLE_DE_PAIE_MOIS_ANNEE.csv'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
