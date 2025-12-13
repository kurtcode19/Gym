import 'package:flutter/material.dart';
import 'package:gym/models/pt_session.dart';
import 'package:gym/providers/database_helper.dart';

class DetailedPTSession {
  final PTSession session;
  final String customerName;
  final String trainerName;

  // NEW for finance income calculation
  final double? packagePrice;
  final int? packageTotalSessions;

  DetailedPTSession({
    required this.session,
    required this.customerName,
    required this.trainerName,
    this.packagePrice,
    this.packageTotalSessions,
  });

  get startTime => null;

  get customerId => null;
}


class PTProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  List<DetailedPTSession> _sessions = [];
  bool _isLoading = false;

  PTProvider(this._dbHelper) {
    fetchSessions();
  }

  List<DetailedPTSession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  // -----------------------------------------------
  // LOAD ALL DETAILED PT SESSIONS FROM DATABASE
  // -----------------------------------------------
  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getDetailedPTSessions();

_sessions = data.map((item) => DetailedPTSession(
  session: PTSession.fromJson(item),
  customerName: '${item['c_first']} ${item['c_last']}',
  trainerName: '${item['t_first']} ${item['t_last']}',
  packagePrice: item['package_price'] != null ? item['package_price'] * 1.0 : null,
  packageTotalSessions: item['package_total'],
)).toList();

    } catch (e) {
      print("Error fetching PT sessions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------
  // CHECK TRAINER AVAILABILITY
  // -----------------------------------------------
  bool checkAvailability(
    String trainerId,
    DateTime start,
    int duration, {
    String? excludeId,
  }) {
    final end = start.add(Duration(minutes: duration));

    for (var s in _sessions) {
      if (s.session.sessionId == excludeId) continue;
      if (s.session.trainerId != trainerId) continue;

      final sStart = s.session.startTime;
      final sEnd = sStart.add(Duration(minutes: s.session.durationMinutes));

      if (start.isBefore(sEnd) && end.isAfter(sStart)) {
        return false;
      }
    }
    return true;
  }

  // -----------------------------------------------
  // ADD PT SESSION (AND DEDUCT PACKAGE CREDIT)
  // -----------------------------------------------
  Future<void> addSession(PTSession session) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Save session
      await txn.insert('PT_SESSION', session.toJson());

      // Deduct package credit
      if (session.packageId != null) {
        await txn.rawUpdate(
          'UPDATE TRAINER_PACKAGE SET sessions_used = sessions_used + 1 WHERE package_id = ?',
          [session.packageId],
        );
      }
    });

    await fetchSessions();
  }

  // -----------------------------------------------
  // DELETE PT SESSION (AND REFUND PACKAGE CREDIT)
  // -----------------------------------------------
  Future<void> deleteSession(PTSession session) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        'PT_SESSION',
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
      );

      if (session.packageId != null) {
        await txn.rawUpdate(
          'UPDATE TRAINER_PACKAGE SET sessions_used = sessions_used - 1 WHERE package_id = ?',
          [session.packageId],
        );
      }
    });

    await fetchSessions();
  }

  // ==================================================
  // ========== TRAINER PAYROLL LOGIC BELOW ===========
  // ==================================================

  // --------------------------------------------------
  // COUNT PT SESSIONS THAT ARE:
  // Completed + Paid by client + NOT YET paid to trainer
  // --------------------------------------------------
  int countEligibleSessions(
    String trainerId,
    DateTime start,
    DateTime end,
  ) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _sessions.where((s) {
      if (s.session.trainerId != trainerId) return false;
      if (s.session.status != "Completed") return false;
      if (s.session.isPaid == 0) return false;        // client must have paid
      if (s.session.trainerPaid == 1) return false;   // avoid double-paying

      final time = s.session.startTime;
      return !time.isBefore(startDate) && !time.isAfter(endDate);
    }).length;
  }

  // --------------------------------------------------
  // MARK ALL ELIGIBLE SESSIONS AS PAID TO TRAINER
  // --------------------------------------------------
  Future<void> markSessionsAsTrainerPaid(
    String trainerId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;

    final startMs = DateTime(start.year, start.month, start.day)
        .millisecondsSinceEpoch;

    final endMs = DateTime(end.year, end.month, end.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    await db.rawUpdate('''
      UPDATE PT_SESSION
      SET trainer_paid = 1
      WHERE trainer_id = ?
        AND status = 'Completed'
        AND is_paid = 1
        AND trainer_paid = 0
        AND start_time BETWEEN ? AND ?
    ''', [trainerId, startMs, endMs]);

    await fetchSessions();
  }
}
