// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:gym/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  void _loadBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_backup_date');
    if (dateStr != null) {
      setState(() {
        _lastBackupDate = DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(dateStr));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Settings & Backup"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Data Management"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.cloud_upload, color: Colors.white),
                  ),
                  title: const Text("Backup Data"),
                  subtitle: Text(_lastBackupDate != null 
                      ? "Last backup: $_lastBackupDate" 
                      : "Never backed up"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await _backupService.createBackup(context);
                    _loadBackupInfo(); // Refresh date display
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.restore, color: Colors.white),
                  ),
                  title: const Text("Restore Data"),
                  subtitle: const Text("Import a .db file"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _backupService.restoreBackup(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          // Add other settings here (e.g. Reset PIN)
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
    );
  }
}