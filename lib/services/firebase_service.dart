import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/staff.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../models/advance.dart';
import '../models/campus.dart';
import '../models/user.dart' as app_model;
import '../auth/models/app_user.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  app_model.User? _currentAppUser;

  void setAppUser(app_model.User? user) {
    _currentAppUser = user;
  }

  /// Applies Role-Based Access Control filtering to any campus-based query.
  Query _applyRbacFilter(Query query, String? requestedCampus) {
    if (_currentAppUser == null) return query; // Fallback or unauthenticated
    
    final role = roleFromString(_currentAppUser!.role);
    if (role.isSuperUser) {
      if (requestedCampus != null && requestedCampus.isNotEmpty) {
        return query.where('campus', isEqualTo: requestedCampus);
      }
      return query;
    }
    
    // Admin role
    final campuses = _currentAppUser!.assignedCampuses;
    if (campuses.isEmpty) {
      // Force empty result by querying for an impossible campus
      return query.where('campus', isEqualTo: '___NONE___'); 
    }
    
    if (requestedCampus != null && requestedCampus.isNotEmpty) {
      if (campuses.contains(requestedCampus)) {
        return query.where('campus', isEqualTo: requestedCampus);
      } else {
        return query.where('campus', isEqualTo: '___UNAUTHORIZED___');
      }
    }
    
    return query.where('campus', whereIn: campuses);
  }

  void _verifyCampusAccess(String? campus) {
    if (_currentAppUser == null) return; // Allow bypass for login/initialization
    final role = roleFromString(_currentAppUser!.role);
    if (role.isSuperUser) return;
    
    if (campus == null || campus.isEmpty) {
      throw Exception('Unauthorized: Campus is required for this operation.');
    }
    if (!_currentAppUser!.assignedCampuses.contains(campus)) {
      throw Exception('Unauthorized: You do not have permission to manage data for $campus.');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Staff methods
  Future<(List<Staff>, DocumentSnapshot?)> getStaff({
    String? campus,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('staff').orderBy('name');
      query = _applyRbacFilter(query, campus);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.limit(limit).get();

      final staffList = snapshot.docs.map((doc) {
        return Staff.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      final lastVisible = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (staffList, lastVisible);
    } catch (e) {
      debugPrint('ERROR in getStaff: $e');
      return (<Staff>[], null);
    }
  }

  Future<List<Staff>> getAllStaff({
    String? campus,
    bool onlyActive = false,
  }) async {
    try {
      // Avoid composite index issues by not using orderBy with filters
      Query query = _firestore.collection('staff');
      query = _applyRbacFilter(query, campus);

      if (onlyActive) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();

      final staffList = snapshot.docs.map((doc) {
        return Staff.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort locally to avoid index requirements
      staffList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return staffList;
    } catch (e) {
      print('Error getting all staff: $e');
      rethrow; // Rethrow so UI can show the error
    }
  }

  Future<Staff?> getStaffById(String id) async {
    try {
      final doc = await _firestore.collection('staff').doc(id).get();
      if (!doc.exists) return null;

      return Staff.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting staff by id: $e');
      return null;
    }
  }

  Future<String> addStaff(Staff staff) async {
    try {
      _verifyCampusAccess(staff.campus);
      final data = staff.toFirestore();
      if (staff.password != null && staff.password!.isNotEmpty) {
        data['password'] = _hashPassword(staff.password!);
      }
      final docRef = await _firestore
          .collection('staff')
          .add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding staff: $e');
      rethrow;
    }
  }

  Future<void> updateStaff(String id, Staff staff) async {
    try {
      _verifyCampusAccess(staff.campus);
      final data = staff.toFirestore();
      if (staff.password != null && staff.password!.isNotEmpty) {
        // Only hash if it's not already a 64-char SHA256 string
        if (staff.password!.length != 64) {
          data['password'] = _hashPassword(staff.password!);
        }
      }
      await _firestore.collection('staff').doc(id).update(data);
    } catch (e) {
      debugPrint('Error updating staff: $e');
      rethrow;
    }
  }

  // Soft delete - marks staff as inactive instead of removing
  Future<void> deleteStaff(String id) async {
    try {
      await _firestore.collection('staff').doc(id).update({'isActive': false});
    } catch (e) {
      print('Error deleting staff: $e');
      rethrow;
    }
  }

  // Restore deleted staff - marks as active again
  Future<void> restoreStaff(String id) async {
    try {
      await _firestore.collection('staff').doc(id).update({'isActive': true});
    } catch (e) {
      print('Error restoring staff: $e');
      rethrow;
    }
  }

  // Verify staff login credentials
  Future<Staff?> verifyStaffCredentials(String phone, String password) async {
    try {
      final snapshot = await _firestore
          .collection('staff')
          .where('phone', isEqualTo: phone)
          .where('isActive', isEqualTo: true)
          .get();

      final hashedPassword = _hashPassword(password);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final storedPassword = data['password'] as String?;
        if (storedPassword == null) continue;

        if (storedPassword == hashedPassword) {
          return Staff.fromFirestore(data, doc.id);
        } else if (storedPassword == password) {
          // Transparent migration for legacy plaintext passwords
          await doc.reference.update({'password': hashedPassword});
          return Staff.fromFirestore(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying staff credentials: $e');
      return null;
    }
  }

  // Get deleted (inactive) staff for restoration
  Future<List<Staff>> getDeletedStaff({String? campus}) async {
    try {
      Query query = _firestore
          .collection('staff')
          .where('isActive', isEqualTo: false);
      query = _applyRbacFilter(query, campus);

      final snapshot = await query.get();

      final staffList = snapshot.docs.map((doc) {
        return Staff.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      staffList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return staffList;
    } catch (e) {
      print('Error getting deleted staff: $e');
      return [];
    }
  }

  // Get specific staff salaries
  Future<List<Salary>> getStaffSalaries(String staffId) async {
    try {
      print('Firebase: Getting salaries for staffId: $staffId');
      // Query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection('salaries')
          .where('staff_id', isEqualTo: staffId)
          .get();

      print('Firebase: Found ${snapshot.docs.length} salary documents');

      final salaries = snapshot.docs.map((doc) {
        return Salary.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Sort in memory instead of using composite index
      salaries.sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return b.month.compareTo(a.month);
      });

      return salaries;
    } catch (e) {
      print('Error getting staff salaries: $e');
      return [];
    }
  }

  // Get specific staff attendance
  Future<List<Attendance>> getStaffAttendance(String staffId) async {
    try {
      print('Firebase: Getting attendance for staffId: $staffId');
      // Query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection('attendance')
          .where('staff_id', isEqualTo: staffId)
          .get();

      print('Firebase: Found ${snapshot.docs.length} attendance documents');

      final attendanceList = snapshot.docs.map((doc) {
        return Attendance.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Sort in memory instead of using composite index
      attendanceList.sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return b.month.compareTo(a.month);
      });

      return attendanceList;
    } catch (e) {
      print('Error getting staff attendance: $e');
      return [];
    }
  }

  // Attendance methods
  Future<List<Attendance>> getAttendance({
    int? month,
    int? year,
    String? staffId,
  }) async {
    try {
      Query query = _firestore.collection('attendance');

      if (month != null) query = query.where('month', isEqualTo: month);
      if (year != null) query = query.where('year', isEqualTo: year);
      if (staffId != null) query = query.where('staff_id', isEqualTo: staffId);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return Attendance.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  Future<String> addAttendance(Attendance attendance) async {
    try {
      final docRef = await _firestore
          .collection('attendance')
          .add(attendance.toFirestore());
      await recalculateAndSaveSalary(
        attendance.staffId,
        attendance.month,
        attendance.year,
      );
      return docRef.id;
    } catch (e) {
      print('Error adding attendance: $e');
      rethrow;
    }
  }

  Future<void> updateAttendance(String id, Attendance attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(id)
          .update(attendance.toFirestore());
      await recalculateAndSaveSalary(
        attendance.staffId,
        attendance.month,
        attendance.year,
      );
    } catch (e) {
      print('Error updating attendance: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(
    String id,
    String staffId,
    int month,
    int year,
  ) async {
    try {
      await _firestore.collection('attendance').doc(id).delete();
      // Recalculate salary after deleting attendance
      await recalculateAndSaveSalary(staffId, month, year);
    } catch (e) {
      print('Error deleting attendance: $e');
      rethrow;
    }
  }

  // Salary methods
  Stream<List<Salary>> getSalariesStream({
    int? month,
    int? year,
    String? campus,
  }) {
    Query query = _firestore.collection('salaries');

    if (month != null) query = query.where('month', isEqualTo: month);
    if (year != null) query = query.where('year', isEqualTo: year);
    query = _applyRbacFilter(query, campus);

    return query.snapshots().map((snapshot) {
      final salaries = snapshot.docs.map((doc) {
        return Salary.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      salaries.sort((a, b) => a.staffName.compareTo(b.staffName));
      return salaries;
    });
  }

  Future<List<Salary>> getSalaries({
    int? month,
    int? year,
    String? campus,
    String? staffId,
  }) async {
    try {
      Query query = _firestore.collection('salaries');

      if (month != null) query = query.where('month', isEqualTo: month);
      if (year != null) query = query.where('year', isEqualTo: year);
      query = _applyRbacFilter(query, campus);
      if (staffId != null) {
        query = query.where('staff_id', isEqualTo: staffId);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return Salary.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting salaries: $e');
      return [];
    }
  }

  Future<String> addSalary(Salary salary) async {
    try {
      _verifyCampusAccess(salary.campus);
      final docRef = await _firestore
          .collection('salaries')
          .add(salary.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding salary: $e');
      rethrow;
    }
  }

  Future<void> updateSalary(String id, Salary salary) async {
    try {
      _verifyCampusAccess(salary.campus);
      await _firestore
          .collection('salaries')
          .doc(id)
          .update(salary.toFirestore());
    } catch (e) {
      print('Error updating salary: $e');
      rethrow;
    }
  }

  Future<void> deleteSalary(String id) async {
    try {
      await _firestore.collection('salaries').doc(id).delete();
    } catch (e) {
      print('Error deleting salary: $e');
      rethrow;
    }
  }

  Future<void> toggleSalaryPaidStatus(String id, bool isPaid) async {
    try {
      await _firestore.collection('salaries').doc(id).update({
        'is_paid': isPaid,
        'paid_date': isPaid ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      print('Error toggling salary paid status: $e');
      rethrow;
    }
  }

  /// Mark multiple salaries as paid in a batch operation
  Future<void> batchMarkSalariesAsPaid(List<String> salaryIds) async {
    try {
      final paidDate = DateTime.now().toIso8601String();

      // Process in batches of 10 to stay under Firestore limits
      const batchSize = 10;
      for (var i = 0; i < salaryIds.length; i += batchSize) {
        final end = (i + batchSize < salaryIds.length)
            ? i + batchSize
            : salaryIds.length;
        final batchIds = salaryIds.sublist(i, end);

        await Future.wait(
          batchIds.map(
            (id) => _firestore.collection('salaries').doc(id).update({
              'is_paid': true,
              'paid_date': paidDate,
            }),
          ),
        );
      }
    } catch (e) {
      print('Error batch marking salaries as paid: $e');
      rethrow;
    }
  }

  /// Mark multiple salaries as unpaid in a batch operation
  Future<void> batchMarkSalariesAsUnpaid(List<String> salaryIds) async {
    try {
      // Process in batches of 10 to stay under Firestore limits
      const batchSize = 10;
      for (var i = 0; i < salaryIds.length; i += batchSize) {
        final end = (i + batchSize < salaryIds.length)
            ? i + batchSize
            : salaryIds.length;
        final batchIds = salaryIds.sublist(i, end);

        await Future.wait(
          batchIds.map(
            (id) => _firestore.collection('salaries').doc(id).update({
              'is_paid': false,
              'paid_date': null,
            }),
          ),
        );
      }
    } catch (e) {
      print('Error batch marking salaries as unpaid: $e');
      rethrow;
    }
  }

  Future<void> paySalary(String salaryId, double amount, String date, String note, String status, double totalSalary) async {
    try {
      await _firestore.collection('salaries').doc(salaryId).update({
        'paid_amount': amount,
        'paid_date': date,
        'notes': note,
        'status': status,
        'remaining_amount': totalSalary - amount,
        'is_paid': status == 'Paid',
      });
    } catch (e) {
      print('Error paying salary: $e');
      rethrow;
    }
  }

  Future<void> recalculateAndSaveSalary(
    String staffId,
    int month,
    int year,
  ) async {
    try {
      final staff = await getStaffById(staffId);
      if (staff == null) throw Exception('Staff not found');

      final attendanceList = await getAttendance(
        month: month,
        year: year,
        staffId: staffId,
      );

      // Sum up raw absents, lates, and half-leaves
      final rawAbsents = attendanceList.fold<int>(
        0,
        (sum, att) => sum + att.absents,
      );
      final totalLates = attendanceList.fold<int>(
        0,
        (sum, att) => sum + att.lates,
      );
      final totalHalfLeaves = attendanceList.fold<int>(
        0,
        (sum, att) => sum + att.halfLeaves,
      );

      // Calculate effective absents:
      // - 3 lates = 1 absent
      // - 2 half-leaves = 1 absent
      final latesAsAbsents = totalLates ~/ 3;
      final halfLeavesAsAbsents = totalHalfLeaves / 2;
      final effectiveAbsents =
          rawAbsents + latesAsAbsents + halfLeavesAsAbsents;

      final absentDeduction = (staff.salary / 30) * effectiveAbsents;

      final (advances, _) = await getAdvances(staffId: staffId);
      // Filter advances by the month/year they should be deducted from
      final advancesInMonth = advances.where((adv) {
        return adv.advanceMonth == month && adv.advanceYear == year;
      });
      final totalAdvances = advancesInMonth.fold<double>(
        0,
        (sum, adv) => sum + adv.advanceAmount,
      );

      final totalDeduction = absentDeduction + totalAdvances;
      final finalSalary = staff.salary - totalDeduction;

      final existingSalaries = await getSalaries(
        month: month,
        year: year,
        staffId: staffId,
      );

      // Preserve existing paid status if available
      bool isPaid = false;
      String? paidDate;
      double paidAmount = 0.0;
      String status = 'Pending';
      String? notes;
      String existingId = '';

      if (existingSalaries.isNotEmpty) {
        final existing = existingSalaries.first;
        isPaid = existing.isPaid;
        paidDate = existing.paidDate;
        paidAmount = existing.paidAmount;
        status = existing.status;
        notes = existing.notes;
        existingId = existing.id;
      }

      final salaryData = Salary(
        id: existingId,
        staffId: staff.id,
        staffName: staff.name,
        month: month,
        year: year,
        basicSalary: staff.salary,
        deduction: totalDeduction,
        totalSalary: finalSalary,
        absents: effectiveAbsents,
        lates: totalLates,
        advanceAmount: totalAdvances,
        campus: staff.campus,
        phone: staff.phone,
        isPaid: isPaid,
        paidDate: paidDate,
        paidAmount: paidAmount,
        remainingAmount: finalSalary - paidAmount,
        status: status,
        notes: notes,
      );

      if (existingSalaries.isNotEmpty) {
        await updateSalary(salaryData.id, salaryData);
      } else {
        await addSalary(salaryData);
      }
    } catch (e) {
      print('Error recalculating salary for staff $staffId: $e');
      rethrow;
    }
  }

  Future<void> batchRecalculateSalaries(
    int month,
    int year, {
    String? campus,
  }) async {
    try {
      // Only recalculate for ACTIVE staff
      final staffList = await getAllStaff(campus: campus, onlyActive: true);

      // Process in batches of 10 to avoid overwhelming the database/network
      // while still being much faster than sequential
      int batchSize = 10;
      for (var i = 0; i < staffList.length; i += batchSize) {
        var end = (i + batchSize < staffList.length)
            ? i + batchSize
            : staffList.length;
        var batch = staffList.sublist(i, end);

        await Future.wait(
          batch.map((staff) => recalculateAndSaveSalary(staff.id, month, year)),
        );
      }
    } catch (e) {
      print('Error in batch recalculation: $e');
      rethrow;
    }
  }

  // Advance methods
  Future<(List<Advance>, DocumentSnapshot?)> getAdvances({
    String? staffId,
    int? month,
    int? year,
    DocumentSnapshot? lastDoc,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('advances');

      // If filtering by staffId, only use where clause (no orderBy to avoid composite index)
      // We'll sort in-memory instead
      if (staffId != null && staffId.isNotEmpty) {
        query = query.where('staff_id', isEqualTo: staffId);
      } else {
        // Only order by date when NOT filtering by staff (simple index)
        query = query.orderBy('advance_date', descending: true);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      // When filtering by date, fetch more to compensate for in-memory filtering
      final fetchLimit = (month != null && year != null)
          ? ((limit ?? 20) * 3)
          : (limit ?? 20);

      query = query.limit(fetchLimit);

      final snapshot = await query.get();

      var advances = snapshot.docs.map((doc) {
        return Advance.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Sort in-memory by date (descending) if we filtered by staff
      if (staffId != null && staffId.isNotEmpty) {
        advances.sort((a, b) => b.advanceDate.compareTo(a.advanceDate));
      }

      // Filter by date in-memory if month and year are provided
      if (month != null && year != null) {
        advances = advances.where((advance) {
          try {
            final advDate = DateTime.parse(advance.advanceDate);
            return advDate.month == month && advDate.year == year;
          } catch (e) {
            return false;
          }
        }).toList();

        // Limit after filtering
        if (limit != null && advances.length > limit) {
          advances = advances.sublist(0, limit);
        }
      }

      final lastVisible = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (advances, lastVisible);
    } catch (e) {
      print('Error getting advances: $e');
      return (<Advance>[], null);
    }
  }

  Future<String> addAdvance(Advance advance) async {
    try {
      final docRef = await _firestore
          .collection('advances')
          .add(advance.toFirestore());
      final advDate = DateTime.parse(advance.advanceDate);
      await recalculateAndSaveSalary(
        advance.staffId,
        advDate.month,
        advDate.year,
      );
      return docRef.id;
    } catch (e) {
      print('Error adding advance: $e');
      rethrow;
    }
  }

  Future<void> deleteAdvance(String id) async {
    try {
      final advanceDoc = await _firestore.collection('advances').doc(id).get();
      if (!advanceDoc.exists) return;
      final advance = Advance.fromFirestore(advanceDoc.data()!, id);

      await _firestore.collection('advances').doc(id).delete();

      final advDate = DateTime.parse(advance.advanceDate);
      await recalculateAndSaveSalary(
        advance.staffId,
        advDate.month,
        advDate.year,
      );
    } catch (e) {
      print('Error deleting advance: $e');
      rethrow;
    }
  }

  // Dashboard methods
  Future<Map<String, dynamic>> getDashboardData({String? campus}) async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // 1. Staff Count
      Query staffQuery = _firestore.collection('staff');
      staffQuery = _applyRbacFilter(staffQuery, campus);
      final staffSnapshot = await staffQuery.get();
      final totalStaff = staffSnapshot.size;

      // 2. Total Salary Paid (for current month)
      Query salaryQuery = _firestore
          .collection('salaries')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear);
      salaryQuery = _applyRbacFilter(salaryQuery, campus);
      final salarySnapshot = await salaryQuery.get();

      final totalSalaryAmount = salarySnapshot.docs.fold<double>(
        0,
        (sum, doc) =>
            sum +
            ((doc.data() as Map<String, dynamic>)['total_salary'] as num? ??
                0.0),
      );

      // 3. Total Absents (for current month)
      Query attendanceQuery = _firestore
          .collection('attendance')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear);

      List<String> allowedStaffIds = staffSnapshot.docs.map((doc) => doc.id).toList();

      final attendanceSnapshot = await attendanceQuery.get();
      int totalAbsents = 0;

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Filter attendance by staff that belong to allowed campuses
        if (allowedStaffIds.contains(data['staff_id'])) {
          totalAbsents += (data['absents'] as num? ?? 0).toInt();
        }
      }

      // 4. Total Advances (Count of advances given this month)
      // We need to filter by date string 'yyyy-MM-dd'
      final startOfMonth =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
      final endOfMonth =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-31";

      Query advanceQuery = _firestore
          .collection('advances')
          .where('advance_date', isGreaterThanOrEqualTo: startOfMonth)
          .where('advance_date', isLessThanOrEqualTo: endOfMonth);

      final advanceSnapshot = await advanceQuery.get();
      int totalAdvancesCount = 0;

      for (var doc in advanceSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Filter advances by staff that belong to allowed campuses
        if (allowedStaffIds.contains(data['staff_id'])) {
          totalAdvancesCount++;
        }
      }

      return {
        'total_staff': totalStaff,
        'total_salary_amount': totalSalaryAmount,
        'total_absents': totalAbsents,
        'total_advances_count': totalAdvancesCount,
      };
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {
        'total_staff': 0,
        'total_salary_amount': 0.0,
        'total_absents': 0,
        'total_advances_count': 0,
      };
    }
  }

  // Campus methods
  Future<List<Campus>> getCampuses() async {
    try {
      final snapshot = await _firestore
          .collection('campuses')
          .orderBy('name')
          .get();

      var campuses = snapshot.docs.map((doc) {
        return Campus.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (_currentAppUser != null) {
        final role = roleFromString(_currentAppUser!.role);
        if (role.isAdmin) {
          campuses = campuses
              .where((c) => _currentAppUser!.assignedCampuses.contains(c.name))
              .toList();
        }
      }
      return campuses;
    } catch (e) {
      print('Error getting campuses: $e');
      return [];
    }
  }

  Future<String> addCampus(String name, {String? location}) async {
    try {
      final docRef = await _firestore.collection('campuses').add({
        'name': name,
        'location': location,
        'created_by': _currentAppUser?.id,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error adding campus: $e');
      rethrow;
    }
  }

  Future<void> deleteCampus(String id) async {
    try {
      await _firestore.collection('campuses').doc(id).delete();
    } catch (e) {
      print('Error deleting campus: $e');
      rethrow;
    }
  }

  Future<void> updateCampus(String id, {required String name, String? location}) async {
    try {
      await _firestore.collection('campuses').doc(id).update({
        'name': name,
        'location': location,
      });
    } catch (e) {
      print('Error updating campus: $e');
      rethrow;
    }
  }

  /// Returns a map of campusName -> list of admin usernames assigned to that campus.
  Future<Map<String, List<String>>> getAdminsByCampus() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final Map<String, List<String>> result = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final username = data['username'] as String? ?? 'Unknown';
        final assignedCampuses = data['assigned_campuses'] as List<dynamic>? ?? [];

        for (var campus in assignedCampuses) {
          final campusName = campus.toString();
          result.putIfAbsent(campusName, () => []);
          result[campusName]!.add(username);
        }
      }

      return result;
    } catch (e) {
      print('Error getting admins by campus: $e');
      return {};
    }
  }

  // User management methods
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // Fetch without orderBy to avoid index requirements
      final snapshot = await _firestore.collection('users').get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort locally by username
      users.sort(
        (a, b) => (a['username'] ?? '').toString().toLowerCase().compareTo(
          (b['username'] ?? '').toString().toLowerCase(),
        ),
      );

      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<String> addUser({
    required String username,
    required String email,
    required String password,
    required String role,
    List<String> assignedCampuses = const [],
  }) async {
    // Generate a random document ID for the user
    final docRef = _firestore.collection('users').doc();
    final docId = docRef.id;

    try {
      // First, add user to Firestore (this is reliable)
      await docRef.set({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'assigned_campuses': assignedCampuses,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('User added to Firestore with ID: $docId');

      // Now try to create in Firebase Auth
      // This may fail due to plugin bug, but login flow will auto-create on first login
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('User also created in Firebase Auth');
      } catch (authError) {
        // This is often the plugin bug, not a real error
        // The login flow will handle creating the Auth user on first login
        print(
          'Firebase Auth creation had an error (may be plugin bug): $authError',
        );
        print('User will be auto-created in Firebase Auth on first login');
      }

      return docId;
    } catch (e) {
      print('Error adding user to Firestore: $e');
      // Try to clean up if Firestore add failed
      try {
        await docRef.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> updateUser({
    required String id,
    required String username,
    required String email,
    String? password,
    required String role,
    List<String> assignedCampuses = const [],
  }) async {
    try {
      final updateData = <String, dynamic>{
        'username': username,
        'email': email,
        'role': role,
        'assigned_campuses': assignedCampuses,
      };

      // Only update password if provided
      if (password != null && password.isNotEmpty) {
        updateData['password'] = password;
      }

      await _firestore.collection('users').doc(id).update(updateData);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}
