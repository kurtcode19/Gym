// lib/services/background_membership_service.dart
import 'dart:async';
import 'package:gym/services/membership_status_service.dart';
import 'package:gym/providers/database_helper.dart';

class BackgroundMembershipService {
  final MembershipStatusService _statusService;
  Timer? _timer;

  BackgroundMembershipService(this._statusService);

  // Start checking for expired memberships periodically
  void startExpiryChecks() {
    // Check immediately when service starts
    _statusService.checkAndUpdateExpiredMemberships();
    
    // Then check every hour (you can adjust the interval)
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _statusService.checkAndUpdateExpiredMemberships();
    });
  }

  void stopExpiryChecks() {
    _timer?.cancel();
    _timer = null;
  }

  // Manual check (can be called from UI)
  Future<void> manualExpiryCheck() async {
    await _statusService.checkAndUpdateExpiredMemberships();
  }
}