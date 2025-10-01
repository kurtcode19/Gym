// lib/services/membership_status_service.dart - UPDATED
import 'package:gym/providers/database_helper.dart';
import 'package:gym/models/membership.dart';

class MembershipStatusService {
  final DatabaseHelper _dbHelper;

  MembershipStatusService(this._dbHelper);

  // Update membership status when payment is completed
  Future<void> activateMembership(String membershipId) async {
    try {
      print('🔍 Activating membership: $membershipId');
      
      final memberships = await _dbHelper.getMemberships();
      print('📋 Found ${memberships.length} memberships total');
      
      final membershipMap = memberships.firstWhere(
        (m) => m['membership_id'] == membershipId,
        orElse: () => {},
      );
      
      if (membershipMap.isNotEmpty) {
        print('✅ Found membership to activate: ${membershipMap['membership_id']}');
        print('📝 Current status: ${membershipMap['status']}');
        
        final membership = Membership.fromJson(membershipMap);
        final updatedMembership = membership.copyWith(
          status: MembershipStatus.active,
        );
        
        print('🔄 Updating membership status to: ${updatedMembership.status.name}');
        
        await _dbHelper.updateMembership(updatedMembership.toJson());
        print('✅ Membership $membershipId activated successfully');
      } else {
        print('❌ Membership not found: $membershipId');
      }
    } catch (e) {
      print('❌ Error activating membership: $e');
      print('Stack trace: ${e.toString()}');
    }
  }

  // Check and update expired memberships
  Future<void> checkAndUpdateExpiredMemberships() async {
    try {
      print('🔍 Checking for expired memberships...');
      final memberships = await _dbHelper.getMemberships();
      final now = DateTime.now();
      int updatedCount = 0;
      
      for (final membershipMap in memberships) {
        final membership = Membership.fromJson(membershipMap);
        
        if (membership.status == MembershipStatus.active && 
            membership.isExpired) {
          print('🔄 Marking expired membership: ${membership.membershipId}');
          final expiredMembership = membership.copyWith(
            status: MembershipStatus.expired,
          );
          
          await _dbHelper.updateMembership(expiredMembership.toJson());
          updatedCount++;
          print('✅ Membership ${membership.membershipId} marked as expired');
        }
      }
      print('📊 Total memberships updated: $updatedCount');
    } catch (e) {
      print('❌ Error checking expired memberships: $e');
    }
  }

  // Get active memberships count
  Future<int> getActiveMembershipsCount() async {
    try {
      final memberships = await _dbHelper.getMemberships();
      return memberships.where((m) {
        final membership = Membership.fromJson(m);
        return membership.isActive;
      }).length;
    } catch (e) {
      print('Error getting active memberships count: $e');
      return 0;
    }
  }
}