// lib/services/backup_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym/providers/database_helper.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite to verify file

class BackupService {
  static const String _lastBackupKey = 'last_backup_date';

  // 1. BACKUP FUNCTION
  Future<void> createBackup(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();
      
      // Create formatted filename
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final fileName = 'gym_backup_$dateStr.db';

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final backupPath = '${tempDir.path}/$fileName';

      // Copy current DB
      File sourceFile = File(dbPath);
      await sourceFile.copy(backupPath);

      // Share
      final result = await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'Here is my Gym App Backup created on $dateStr',
        subject: 'Gym App Backup',
      );

      if (result.status == ShareResultStatus.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
        
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup successful!')),
          );
        }
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 2. RESTORE FUNCTION (FIXED)
  Future<void> restoreBackup(BuildContext context) async {
    try {
      // 1. Pick the file (Allow any file, we will validate content later)
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        // 2. SAFETY CHECK: Try to open this file as a DB before doing anything
        bool isValid = await _verifyDbFile(selectedFile.path);
        
        if (!isValid) {
          throw Exception("The selected file is not a valid database.");
        }

        // 3. Confirm with User
        if (context.mounted) {
          bool? confirm = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Overwrite Data?'),
              content: const Text('This will REPLACE all current app data with the backup.\n\nThis cannot be undone. The app will restart.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true), 
                  child: const Text('Restore & Restart', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final dbHelper = DatabaseHelper();
            final dbPath = await dbHelper.getDbPath();

            // 4. Close existing connection
            await dbHelper.close();

            // 5. Overwrite the file
            await selectedFile.copy(dbPath);

            // 6. Restart App
            Restart.restartApp(); 
          }
        }
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper to ensure the file is actually an SQLite file
  Future<bool> _verifyDbFile(String path) async {
    try {
      Database db = await openDatabase(path, readOnly: true);
      // Try a simple query to ensure it's valid
      await db.rawQuery('SELECT count(*) FROM sqlite_master');
      await db.close();
      return true;
    } catch (e) {
      print("Verification failed: $e");
      return false;
    }
  }

  // 3. REMINDER CHECK
  Future<bool> needsBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString(_lastBackupKey);
    
    if (lastBackupStr == null) return true; 

    final lastBackup = DateTime.parse(lastBackupStr);
    final daysSince = DateTime.now().difference(lastBackup).inDays;

    return daysSince > 7; 
  }
}