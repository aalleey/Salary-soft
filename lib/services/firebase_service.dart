import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/staff.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../models/advance.dart';
import '../models/campus.dart';
import '../models/user.dart' as app_model;
import 'salary_calculation_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  app_model.User? _currentUser;

  /// Updates the active user session in this service to enable client-level data isolation.
  void setAppUser(app_model.User? user) {
    _currentUser = user;
    debugPrint('FirebaseService: User session set to "${user?.username}" (role: ${user?.role}, clientId: ${user?.clientId})');
  }

  /// Whether the queries should be isolated to a single client (all roles except super_admin)
  bool get _shouldFilterByClient => 
      _currentUser != null && 
      _currentUser!.role != 'super_admin' && 
      _currentUser!.clientId != null && 
      _currentUser!.clientId!.isNotEmpty;
  
  String? get _currentClientId => _currentUser?.clientId;

  // Helper to map document ID to model
  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  // Staff methods
  Future<(List<Staff>, dynamic)> getStaff({
    String? campus,
    dynamic lastDoc,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('staff');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (campus != null && campus.isNotEmpty) {
        query = query.where('campusId', isEqualTo: campus);
      }
      
      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc).limit(limit);
      } else {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      final staffList = snapshot.docs.map((doc) => Staff.fromJson(_withDocId(doc))).toList();
      final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return (staffList, newLastDoc);
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
      Query query = _firestore.collection('staff');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (campus != null && campus.isNotEmpty) {
        query = query.where('campusId', isEqualTo: campus);
      }
      if (onlyActive) {
        query = query.where('status', isEqualTo: 'active');
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Staff.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting all staff: $e');
      rethrow;
    }
  }

  Future<Staff?> getStaffById(String id) async {
    try {
      final doc = await _firestore.collection('staff').doc(id).get();
      if (!doc.exists) return null;
      return Staff.fromJson(_withDocId(doc));
    } catch (e) {
      debugPrint('Error getting staff by id: $e');
      return null;
    }
  }

  Future<String> addStaff(Staff staff) async {
    try {
      final body = staff.toJson();
      if (_shouldFilterByClient) {
        body['clientId'] = _currentClientId;
      }
      final docRef = await _firestore.collection('staff').add(body);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding staff: $e');
      rethrow;
    }
  }

  Future<void> updateStaff(String id, Staff staff) async {
    try {
      final body = staff.toJson();
      if (body['clientId'] == null) {
        body.remove('clientId');
      }
      await _firestore.collection('staff').doc(id).update(body);
    } catch (e) {
      debugPrint('Error updating staff: $e');
      rethrow;
    }
  }

  Future<void> deleteStaff(String id) async {
    try {
      await _firestore.collection('staff').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting staff: $e');
      rethrow;
    }
  }

  Future<void> restoreStaff(String id) async {
    try {
      await _firestore.collection('staff').doc(id).update({'isActive': true});
    } catch (e) {
      debugPrint('Error restoring staff: $e');
      rethrow;
    }
  }

  Future<Staff?> verifyStaffCredentials(String phone, String password) async {
    try {
      Query query = _firestore.collection('staff')
          .where('phone', isEqualTo: phone)
          .where('password', isEqualTo: password);
      
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return Staff.fromJson(_withDocId(snapshot.docs.first));
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying staff credentials: $e');
      return null;
    }
  }

  Future<List<Staff>> getDeletedStaff({String? campus}) async {
    try {
      Query query = _firestore.collection('staff').where('status', isEqualTo: 'inactive');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (campus != null && campus.isNotEmpty) {
        query = query.where('campusId', isEqualTo: campus);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Staff.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting deleted staff: $e');
      return [];
    }
  }

  Future<List<Salary>> getStaffSalaries(String staffId) async {
    try {
      final snapshot = await _firestore.collection('salaries')
          .where('staffId', isEqualTo: staffId)
          .get();
      return snapshot.docs.map((doc) => Salary.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting staff salaries: $e');
      return [];
    }
  }

  Future<List<Attendance>> getStaffAttendance(String staffId) async {
    try {
      final snapshot = await _firestore.collection('attendance')
          .where('staffId', isEqualTo: staffId)
          .get();
      return snapshot.docs.map((doc) => Attendance.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting staff attendance: $e');
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
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (month != null) query = query.where('month', isEqualTo: month);
      if (year != null) query = query.where('year', isEqualTo: year);
      if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Attendance.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return [];
    }
  }

  Future<String> addAttendance(Attendance attendance) async {
    try {
      final body = attendance.toJson();
      if (_shouldFilterByClient) {
        body['clientId'] = _currentClientId;
      }
      final docRef = await _firestore.collection('attendance').add(body);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding attendance: $e');
      rethrow;
    }
  }

  Future<void> updateAttendance(String id, Attendance attendance) async {
    try {
      await _firestore.collection('attendance').doc(id).update(attendance.toJson());
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(String id, String staffId, int month, int year) async {
    try {
      await _firestore.collection('attendance').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting attendance: $e');
      rethrow;
    }
  }

  // Daily check-in/out and logging methods
  Future<void> checkInStaff(String staffId, String staffName) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      // Check for active check-in (checkOutTime == null)
      final existing = await _firestore.collection('attendance')
          .where('staffId', isEqualTo: staffId)
          .where('checkOutTime', isNull: true)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        throw Exception('Staff member is already checked in.');
      }
      
      final attendance = Attendance(
        id: '',
        staffId: staffId,
        staffName: staffName,
        month: now.month,
        year: now.year,
        absents: 0,
        lates: 0,
        halfLeaves: 0,
        date: dateStr,
        checkInTime: now.toIso8601String(),
        checkOutTime: null,
        totalHours: 0.0,
        status: 'present',
      );
      
      final body = attendance.toJson();
      if (_shouldFilterByClient) {
        body['clientId'] = _currentClientId;
      }
      await _firestore.collection('attendance').add(body);
      debugPrint('FirebaseService: Checked in $staffName on $dateStr');
    } catch (e) {
      debugPrint('Error in checkInStaff: $e');
      rethrow;
    }
  }

  Future<void> checkOutStaff(String staffId) async {
    try {
      final now = DateTime.now();
      
      // Find the active check-in doc (checkOutTime == null)
      final activeQuery = await _firestore.collection('attendance')
          .where('staffId', isEqualTo: staffId)
          .where('checkOutTime', isNull: true)
          .limit(1)
          .get();
      
      if (activeQuery.docs.isEmpty) {
        throw Exception('No active check-in found for this staff member.');
      }
      
      final doc = activeQuery.docs.first;
      final data = doc.data();
      final checkInTimeStr = data['checkInTime'] as String;
      final checkInTime = DateTime.parse(checkInTimeStr);
      
      final totalHours = now.difference(checkInTime).inMilliseconds / (1000.0 * 60.0 * 60.0);
      
      await doc.reference.update({
        'checkOutTime': now.toIso8601String(),
        'totalHours': totalHours,
      });
      debugPrint('FirebaseService: Checked out staff $staffId. Total hours: $totalHours');
    } catch (e) {
      debugPrint('Error in checkOutStaff: $e');
      rethrow;
    }
  }

  Future<Attendance?> getActiveCheckIn(String staffId) async {
    try {
      final activeQuery = await _firestore.collection('attendance')
          .where('staffId', isEqualTo: staffId)
          .where('checkOutTime', isNull: true)
          .limit(1)
          .get();
      
      if (activeQuery.docs.isNotEmpty) {
        return Attendance.fromJson(_withDocId(activeQuery.docs.first));
      }
      return null;
    } catch (e) {
      debugPrint('Error in getActiveCheckIn: $e');
      return null;
    }
  }

  // Salary methods
  Stream<List<Salary>> getSalariesStream({
    int? month,
    int? year,
    String? campus,
  }) {
    Query query = _firestore.collection('salaries');
    if (_shouldFilterByClient) {
      query = query.where('clientId', isEqualTo: _currentClientId);
    }
    if (month != null) query = query.where('month', isEqualTo: month);
    if (year != null) query = query.where('year', isEqualTo: year);
    if (campus != null && campus.isNotEmpty) query = query.where('campus', isEqualTo: campus);

    return query.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => Salary.fromJson(_withDocId(doc))).toList()
    );
  }

  Future<List<Salary>> getSalaries({
    int? month,
    int? year,
    String? campus,
    String? staffId,
  }) async {
    try {
      Query query = _firestore.collection('salaries');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (month != null) query = query.where('month', isEqualTo: month);
      if (year != null) query = query.where('year', isEqualTo: year);
      if (campus != null && campus.isNotEmpty) query = query.where('campus', isEqualTo: campus);
      if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Salary.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting salaries: $e');
      return [];
    }
  }

  Future<String> addSalary(Salary salary) async {
    try {
      final body = salary.toJson();
      if (_shouldFilterByClient) {
        body['clientId'] = _currentClientId;
      }
      final docRef = await _firestore.collection('salaries').add(body);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding salary: $e');
      rethrow;
    }
  }

  Future<void> updateSalary(String id, Salary salary) async {
    try {
      await _firestore.collection('salaries').doc(id).update(salary.toJson());
    } catch (e) {
      debugPrint('Error updating salary: $e');
      rethrow;
    }
  }

  Future<void> deleteSalary(String id) async {
    try {
      await _firestore.collection('salaries').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting salary: $e');
      rethrow;
    }
  }

  Future<void> toggleSalaryPaidStatus(String id, bool isPaid) async {
    try {
      await _firestore.collection('salaries').doc(id).update({
        'isPaid': isPaid,
        'status': isPaid ? 'Paid' : 'Pending',
        'paidDate': isPaid ? DateTime.now().toIso8601String() : null
      });
    } catch (e) {
      debugPrint('Error toggling salary paid status: $e');
      rethrow;
    }
  }

  Future<void> batchMarkSalariesAsPaid(List<String> salaryIds) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var id in salaryIds) {
        DocumentReference ref = _firestore.collection('salaries').doc(id);
        batch.update(ref, {
          'isPaid': true,
          'status': 'Paid',
          'paidDate': DateTime.now().toIso8601String()
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch marking salaries as paid: $e');
      rethrow;
    }
  }

  Future<void> batchMarkSalariesAsUnpaid(List<String> salaryIds) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var id in salaryIds) {
        DocumentReference ref = _firestore.collection('salaries').doc(id);
        batch.update(ref, {
          'isPaid': false,
          'status': 'Pending',
          'paidDate': null
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch marking salaries as unpaid: $e');
      rethrow;
    }
  }

  Future<void> paySalary(String salaryId, double amount, String date, String note, String status, double totalSalary) async {
    try {
      await _firestore.collection('salaries').doc(salaryId).update({
        'paidAmount': amount,
        'paidDate': date,
        'notes': note,
        'status': status,
        'remainingAmount': totalSalary - amount,
        'isPaid': status == 'Paid',
      });
    } catch (e) {
      debugPrint('Error paying salary: $e');
      rethrow;
    }
  }

  Future<void> updateSalaryPayment({
    required String salaryId,
    required double bonus,
    required double otherDeductions,
    required double totalDeduction,
    required double totalSalary,
    required double paidAmount,
    required String paidDate,
    required String notes,
    required String status,
  }) async {
    try {
      final double remaining = totalSalary - paidAmount;
      await _firestore.collection('salaries').doc(salaryId).update({
        'bonus': bonus,
        'otherDeductions': otherDeductions,
        'deduction': totalDeduction,
        'totalSalary': totalSalary,
        'paidAmount': paidAmount,
        'paidDate': paidDate,
        'notes': notes,
        'status': status,
        'remainingAmount': remaining < 0 ? 0.0 : remaining,
        'isPaid': status == 'Paid',
      });
    } catch (e) {
      debugPrint('Error updating salary payment: $e');
      rethrow;
    }
  }

  Future<void> recalculateAndSaveSalary(String staffId, int month, int year) async {
    try {
      // 1. Get staff
      final staff = await getStaffById(staffId);
      if (staff == null) throw Exception('Staff member not found');

      // 2. Get attendance
      final attendanceList = await getAttendance(staffId: staffId, month: month, year: year);
      
      // Separate monthly summaries from daily logs
      final summaries = attendanceList.where((a) => a.date == null).toList();
      final dailyLogs = attendanceList.where((a) => a.date != null).toList();

      double absents = 0.0;
      int lates = 0;
      int halfLeaves = 0;
      double totalWorkingHours = 0.0;
      double totalLectures = 0.0;

      if (summaries.isNotEmpty) {
        final summary = summaries.first;
        absents = summary.absents.toDouble();
        lates = summary.lates;
        halfLeaves = summary.halfLeaves;
        totalWorkingHours = summary.totalWorkingHours;
        totalLectures = summary.totalLectures;
      }

      // If hourly and totalWorkingHours was not manually entered, sum daily logs:
      if (staff.salaryType == 'Hourly' && totalWorkingHours == 0.0) {
        totalWorkingHours = dailyLogs.fold<double>(0.0, (acc, log) => acc + log.totalHours);
      }

      // 3. Get advances
      final advancesTuple = await getAdvances(staffId: staffId, month: month, year: year);
      final advancesList = advancesTuple.$1;
      double advanceAmount = 0.0;
      for (final adv in advancesList) {
        advanceAmount += adv.advanceAmount;
      }

      // 4. Check if salary document already exists in Firestore to keep bonus and otherDeductions
      double bonus = 0.0;
      double otherDeductions = 0.0;
      final existingQuery = await _firestore.collection('salaries')
          .where('staffId', isEqualTo: staffId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final data = existingQuery.docs.first.data();
        bonus = (data['bonus'] as num?)?.toDouble() ?? 0.0;
        otherDeductions = (data['otherDeductions'] as num?)?.toDouble() ?? 0.0;
      }

      // 5. Calculate salary fields using Reusable Salary Calculation Service
      final presents = 30.0 - absents;
      final calcResult = SalaryCalculationService.calculateSalary(
        salaryType: staff.salaryType == 'Lecture' ? 'lecture_based' : (staff.salaryType == 'Hourly' ? 'hourly' : 'monthly'),
        basicSalary: staff.salary,
        hourlyRate: staff.hourlyRate,
        workingHours: totalWorkingHours,
        workingDays: staff.salaryType == 'Lecture' ? totalLectures : presents,
        absents: absents,
        lates: lates.toDouble(),
        halfLeaves: halfLeaves.toDouble(),
        advance: advanceAmount,
        otherDeductions: otherDeductions,
        bonus: bonus,
        calculationType: staff.calculationType,
      );

      double grossSalary = calcResult.grossSalary;
      double deduction = calcResult.deduction;
      double totalSalary = calcResult.totalSalary;

      if (existingQuery.docs.isNotEmpty) {
        final doc = existingQuery.docs.first;
        final data = doc.data();
        
        double paidAmount = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
        double remainingAmount = totalSalary - paidAmount;
        if (remainingAmount < 0) remainingAmount = 0;

        String status = 'Pending';
        bool isPaid = false;
        if (paidAmount >= totalSalary && totalSalary > 0) {
          status = 'Paid';
          isPaid = true;
        } else if (paidAmount > 0) {
          status = 'Partial Paid';
        }

        await doc.reference.update({
          'basicSalary': grossSalary,
          'deduction': deduction,
          'totalSalary': totalSalary,
          'absents': absents,
          'lates': lates,
          'advanceAmount': advanceAmount,
          'remainingAmount': remainingAmount,
          'status': status,
          'isPaid': isPaid,
          'salaryType': staff.salaryType == 'Lecture' ? 'lecture_based' : (staff.salaryType == 'Hourly' ? 'hourly' : 'monthly'),
          'hourlyRate': staff.salaryType == 'Hourly' ? staff.hourlyRate : 0.0,
          'totalHours': staff.salaryType == 'Hourly' ? totalWorkingHours : 0.0,
          'workingDays': staff.salaryType == 'Lecture' ? totalLectures : (staff.salaryType == 'Monthly' && staff.calculationType == 'present_based' ? presents : 30.0 - absents),
          'bonus': bonus,
          'otherDeductions': otherDeductions,
          'calculationDetails': calcResult.details,
        });
        debugPrint('FirebaseService: Recalculated and updated salary for ${staff.name}');
      } else {
        // Create new salary document
        final body = <String, dynamic>{
          'staffId': staffId,
          'staffName': staff.name,
          'month': month,
          'year': year,
          'basicSalary': grossSalary,
          'deduction': deduction,
          'totalSalary': totalSalary,
          'absents': absents,
          'lates': lates,
          'advanceAmount': advanceAmount,
          'campus': staff.campus,
          'phone': staff.phone,
          'isPaid': false,
          'paidDate': null,
          'paidAmount': 0.0,
          'remainingAmount': totalSalary,
          'status': 'Pending',
          'notes': null,
          'salaryType': staff.salaryType == 'Lecture' ? 'lecture_based' : (staff.salaryType == 'Hourly' ? 'hourly' : 'monthly'),
          'hourlyRate': staff.salaryType == 'Hourly' ? staff.hourlyRate : 0.0,
          'totalHours': staff.salaryType == 'Hourly' ? totalWorkingHours : 0.0,
          'workingDays': staff.salaryType == 'Lecture' ? totalLectures : (staff.salaryType == 'Monthly' && staff.calculationType == 'present_based' ? presents : 30.0 - absents),
          'bonus': bonus,
          'otherDeductions': otherDeductions,
          'calculationDetails': calcResult.details,
        };
        if (_shouldFilterByClient) {
          body['clientId'] = _currentClientId;
        } else if (staff.clientId != null) {
          body['clientId'] = staff.clientId;
        }
        await _firestore.collection('salaries').add(body);
        debugPrint('FirebaseService: Recalculated and created new salary for ${staff.name}');
      }
    } catch (e) {
      debugPrint('Error in recalculateAndSaveSalary: $e');
      rethrow;
    }
  }

  Future<void> batchRecalculateSalaries(int month, int year, {String? campus}) async {
    try {
      final staffList = await getAllStaff(campus: campus, onlyActive: true);
      for (final staff in staffList) {
        await recalculateAndSaveSalary(staff.id, month, year);
      }
      debugPrint('FirebaseService: Batch recalculated salaries for ${staffList.length} staff members');
    } catch (e) {
      debugPrint('Error in batchRecalculateSalaries: $e');
      rethrow;
    }
  }

  // Advance methods
  Future<(List<Advance>, dynamic)> getAdvances({
    String? staffId,
    int? month,
    int? year,
    String? campus,
    dynamic lastDoc,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('advances');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      if (staffId != null) query = query.where('staffId', isEqualTo: staffId);
      if (month != null) query = query.where('month', isEqualTo: month);
      if (year != null) query = query.where('year', isEqualTo: year);
      if (campus != null && campus.isNotEmpty) query = query.where('campus', isEqualTo: campus);

      if (lastDoc != null && lastDoc is DocumentSnapshot) {
        query = query.startAfterDocument(lastDoc);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final advances = snapshot.docs.map((doc) => Advance.fromJson(_withDocId(doc))).toList();
      final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      return (advances, newLastDoc);
    } catch (e) {
      debugPrint('Error getting advances: $e');
      return (<Advance>[], null);
    }
  }

  Future<String> addAdvance(Advance advance) async {
    try {
      final body = advance.toJson();
      if (_shouldFilterByClient) {
        body['clientId'] = _currentClientId;
      }
      final docRef = await _firestore.collection('advances').add(body);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding advance: $e');
      rethrow;
    }
  }

  Future<void> deleteAdvance(String id) async {
    try {
      await _firestore.collection('advances').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting advance: $e');
      rethrow;
    }
  }

  // Campus methods
  Future<List<Campus>> getCampuses() async {
    try {
      Query query = _firestore.collection('campuses');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Campus.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting campuses: $e');
      return [];
    }
  }

  Future<String> addCampus(String name, {String? location}) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
      };
      if (location != null) data['address'] = location;
      if (_shouldFilterByClient) {
        data['clientId'] = _currentClientId;
      }
      final docRef = await _firestore.collection('campuses').add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding campus: $e');
      rethrow;
    }
  }

  Future<void> updateCampus(String id, {required String name, String? location}) async {
    try {
      final data = <String, dynamic>{'name': name};
      if (location != null) data['address'] = location;
      await _firestore.collection('campuses').doc(id).update(data);
    } catch (e) {
      debugPrint('Error updating campus: $e');
      rethrow;
    }
  }

  Future<void> deleteCampus(String id) async {
    try {
      await _firestore.collection('campuses').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting campus: $e');
      rethrow;
    }
  }

  Future<bool> hasCampuses() async {
    Query query = _firestore.collection('campuses');
    if (_shouldFilterByClient) {
      query = query.where('clientId', isEqualTo: _currentClientId);
    }
    final snapshot = await query.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  // ---- Users ----
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      Query query = _firestore.collection('users');
      if (_shouldFilterByClient) {
        query = query.where('clientId', isEqualTo: _currentClientId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _withDocId(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<Map<String, List<String>>> getAdminsByCampus() async {
    final users = await getAllUsers();
    final Map<String, List<String>> admins = {};
    for (final user in users) {
      final role = user['role'];
      if (role == 'admin' || role == 'client_admin') {
        final assigned = List<String>.from(user['assigned_campuses'] ?? []);
        for (final campus in assigned) {
          admins.putIfAbsent(campus, () => []).add(user['username'] ?? 'Admin');
        }
      }
    }
    return admins;
  }

  Future<void> addUser({
    required String username,
    required String email,
    required String password,
    required String role,
    required List<String> assignedCampuses,
    required Map<String, bool> permissions,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'assigned_campuses': assignedCampuses,
      'permissions': permissions,
    };
    if (_shouldFilterByClient) {
      body['clientId'] = _currentClientId;
    }
    await _firestore.collection('users').add(body);
  }

  Future<void> updateUser({
    required String id,
    required String username,
    required String email,
    String? password,
    required String role,
    required List<String> assignedCampuses,
    required Map<String, bool> permissions,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'role': role,
      'assigned_campuses': assignedCampuses,
      'permissions': permissions,
    };
    if (password != null) body['password'] = password;
    if (_shouldFilterByClient) {
      body['clientId'] = _currentClientId;
    }
    await _firestore.collection('users').doc(id).update(body);
  }

  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  // ---- Dashboard Data ----
  Future<Map<String, dynamic>> getDashboardData({String? campus}) async {
    try {
      final month = DateTime.now().month;
      final year = DateTime.now().year;

      final staffList = await getAllStaff(campus: campus);
      final salaries = await getSalaries(month: month, year: year, campus: campus);
      final advancesTuple = await getAdvances(month: month, year: year, campus: campus);
      final advances = advancesTuple.$1;

      double totalPaid = 0;
      for (final s in salaries) {
        if (s.isPaid) totalPaid += s.totalSalary;
      }

      return {
        'total_staff': staffList.length,
        'total_salary_amount': totalPaid,
        'total_absents': 0,
        'total_advances_count': advances.length,
      };
    } catch (e) {
      debugPrint('Error getting dashboard data: $e');
      return {
        'total_staff': 0,
        'total_salary_amount': 0.0,
        'total_absents': 0,
        'total_advances_count': 0,
      };
    }
  }
}
