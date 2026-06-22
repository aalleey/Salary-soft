import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/staff.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../models/advance.dart';
import '../models/campus.dart';
import '../models/user.dart' as app_model;
import 'api_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final ApiService _api = ApiService();
  
  void setAppUser(app_model.User? user) {
  }

  // Staff methods
  Future<(List<Staff>, dynamic)> getStaff({
    String? campus,
    dynamic lastDoc,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (campus != null && campus.isNotEmpty) queryParams['campus'] = campus;
      
      final response = await _api.get('staff', queryParams: queryParams);
      final List<dynamic> data = response;
      final staffList = data.map((json) => Staff.fromJson(json)).toList();
      return (staffList, null);
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
      final queryParams = <String, String>{};
      if (campus != null && campus.isNotEmpty) queryParams['campus'] = campus;
      
      final response = await _api.get('staff', queryParams: queryParams);
      final List<dynamic> data = response;
      var staffList = data.map((json) => Staff.fromJson(json)).toList();
      
      if (onlyActive) {
        staffList = staffList.where((s) => s.isActive).toList();
      }
      return staffList;
    } catch (e) {
      debugPrint('Error getting all staff: $e');
      rethrow;
    }
  }

  Future<Staff?> getStaffById(String id) async {
    try {
      final response = await _api.get('staff/$id');
      return Staff.fromJson(response);
    } catch (e) {
      debugPrint('Error getting staff by id: $e');
      return null;
    }
  }

  Future<String> addStaff(Staff staff) async {
    try {
      final response = await _api.post('staff', body: staff.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding staff: $e');
      rethrow;
    }
  }

  Future<void> updateStaff(String id, Staff staff) async {
    try {
      await _api.put('staff/$id', body: staff.toJson());
    } catch (e) {
      debugPrint('Error updating staff: $e');
      rethrow;
    }
  }

  Future<void> deleteStaff(String id) async {
    try {
      await _api.delete('staff/$id');
    } catch (e) {
      debugPrint('Error deleting staff: $e');
      rethrow;
    }
  }

  Future<void> restoreStaff(String id) async {
    try {
      await _api.put('staff/$id', body: {'isActive': true});
    } catch (e) {
      debugPrint('Error restoring staff: $e');
      rethrow;
    }
  }

  Future<Staff?> verifyStaffCredentials(String phone, String password) async {
    try {
      final response = await _api.post('auth/login', body: {
        'email': phone, // Using email field for phone in backend for staff login
        'password': password,
        'role': 'staff'
      });
      return Staff.fromJson(response['user']);
    } catch (e) {
      debugPrint('Error verifying staff credentials: $e');
      return null;
    }
  }

  Future<List<Staff>> getDeletedStaff({String? campus}) async {
    try {
      final staffList = await getAllStaff(campus: campus);
      return staffList.where((s) => !s.isActive).toList();
    } catch (e) {
      debugPrint('Error getting deleted staff: $e');
      return [];
    }
  }

  Future<List<Salary>> getStaffSalaries(String staffId) async {
    try {
      final response = await _api.get('salary', queryParams: {'staffId': staffId});
      final List<dynamic> data = response;
      return data.map((json) => Salary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting staff salaries: $e');
      return [];
    }
  }

  Future<List<Attendance>> getStaffAttendance(String staffId) async {
    try {
      final response = await _api.get('attendance', queryParams: {'staffId': staffId});
      final List<dynamic> data = response;
      return data.map((json) => Attendance.fromJson(json)).toList();
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
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (staffId != null) queryParams['staffId'] = staffId;

      final response = await _api.get('attendance', queryParams: queryParams);
      final List<dynamic> data = response;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return [];
    }
  }

  Future<String> addAttendance(Attendance attendance) async {
    try {
      final response = await _api.post('attendance', body: attendance.toJson());
      await recalculateAndSaveSalary(attendance.staffId, attendance.month, attendance.year);
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding attendance: $e');
      rethrow;
    }
  }

  Future<void> updateAttendance(String id, Attendance attendance) async {
    try {
      await _api.put('attendance/$id', body: attendance.toJson());
      await recalculateAndSaveSalary(attendance.staffId, attendance.month, attendance.year);
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(String id, String staffId, int month, int year) async {
    try {
      await _api.delete('attendance/$id');
      await recalculateAndSaveSalary(staffId, month, year);
    } catch (e) {
      debugPrint('Error deleting attendance: $e');
      rethrow;
    }
  }

  // Salary methods
  Stream<List<Salary>> getSalariesStream({
    int? month,
    int? year,
    String? campus,
  }) async* {
    final salaries = await getSalaries(month: month, year: year, campus: campus);
    yield salaries;
  }

  Future<List<Salary>> getSalaries({
    int? month,
    int? year,
    String? campus,
    String? staffId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (campus != null) queryParams['campus'] = campus;
      if (staffId != null) queryParams['staffId'] = staffId;

      final response = await _api.get('salary', queryParams: queryParams);
      final List<dynamic> data = response;
      return data.map((json) => Salary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting salaries: $e');
      return [];
    }
  }

  Future<String> addSalary(Salary salary) async {
    try {
      final response = await _api.post('salary', body: salary.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding salary: $e');
      rethrow;
    }
  }

  Future<void> updateSalary(String id, Salary salary) async {
    try {
      await _api.put('salary/$id', body: salary.toJson());
    } catch (e) {
      debugPrint('Error updating salary: $e');
      rethrow;
    }
  }

  Future<void> deleteSalary(String id) async {
    try {
      await _api.delete('salary/$id');
    } catch (e) {
      debugPrint('Error deleting salary: $e');
      rethrow;
    }
  }

  Future<void> toggleSalaryPaidStatus(String id, bool isPaid) async {
    try {
      await _api.put('salary/$id', body: {
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
      for (var id in salaryIds) {
        await toggleSalaryPaidStatus(id, true);
      }
    } catch (e) {
      debugPrint('Error batch marking salaries as paid: $e');
      rethrow;
    }
  }

  Future<void> batchMarkSalariesAsUnpaid(List<String> salaryIds) async {
    try {
      for (var id in salaryIds) {
        await toggleSalaryPaidStatus(id, false);
      }
    } catch (e) {
      debugPrint('Error batch marking salaries as unpaid: $e');
      rethrow;
    }
  }

  Future<void> paySalary(String salaryId, double amount, String date, String note, String status, double totalSalary) async {
    try {
      await _api.put('salary/$salaryId', body: {
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

  Future<void> recalculateAndSaveSalary(String staffId, int month, int year) async {
    try {
      await _api.post('salary/generate', body: {
        'staffId': staffId,
        'month': month,
        'year': year
      });
    } catch (e) {
      debugPrint('Error recalculating salary for staff $staffId: $e');
      rethrow;
    }
  }

  Future<void> batchRecalculateSalaries(int month, int year, {String? campus}) async {
    try {
      await _api.post('salary/generate-batch', body: {
        'month': month,
        'year': year,
        'campus': campus
      });
    } catch (e) {
      debugPrint('Error in batch recalculation: $e');
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
      final queryParams = <String, String>{};
      if (staffId != null) queryParams['staffId'] = staffId;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (campus != null) queryParams['campus'] = campus;

      final response = await _api.get('advances', queryParams: queryParams);
      final List<dynamic> data = response;
      final advances = data.map((json) => Advance.fromJson(json)).toList();
      return (advances, null);
    } catch (e) {
      debugPrint('Error getting advances: $e');
      return (<Advance>[], null);
    }
  }

  Future<String> addAdvance(Advance advance) async {
    try {
      final response = await _api.post('advances', body: advance.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding advance: $e');
      rethrow;
    }
  }

  Future<void> deleteAdvance(String id) async {
    try {
      await _api.delete('advances/$id');
    } catch (e) {
      debugPrint('Error deleting advance: $e');
      rethrow;
    }
  }

  // Campus methods
  Future<List<Campus>> getCampuses() async {
    try {
      final response = await _api.get('campuses');
      final List<dynamic> data = response;
      return data.map((json) => Campus.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting campuses: $e');
      return [];
    }
  }

  Future<String> addCampus(String name, {String? location}) async {
    try {
      final response = await _api.post('campuses', body: {
        'name': name,
        if (location != null) 'location': location,
      });
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding campus: $e');
      rethrow;
    }
  }

  Future<void> updateCampus(String id, {required String name, String? location}) async {
    try {
      await _api.put('campuses/$id', body: {
        'name': name,
        if (location != null) 'location': location,
      });
    } catch (e) {
      debugPrint('Error updating campus: $e');
      rethrow;
    }
  }

  Future<void> deleteCampus(String id) async {
    try {
      await _api.delete('campuses/$id');
    } catch (e) {
      debugPrint('Error deleting campus: $e');
      rethrow;
    }
  }

  Future<bool> hasCampuses() async {
    final campuses = await getCampuses();
    return campuses.isNotEmpty;
  }

  // ---- Users ----
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _api.get('users');
      return List<Map<String, dynamic>>.from(response);
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
    await _api.post('users', body: {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'assigned_campuses': assignedCampuses,
      'permissions': permissions,
    });
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
    final body = {
      'username': username,
      'email': email,
      if (password != null) 'password': password,
      'role': role,
      'assigned_campuses': assignedCampuses,
      'permissions': permissions,
    };
    await _api.put('users/$id', body: body);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('users/$id');
  }

  // ---- Dashboard Data ----
  Future<Map<String, dynamic>> getDashboardData({String? campus}) async {
    try {
      final month = DateTime.now().month;
      final year = DateTime.now().year;

      final staffList = await getStaff(campus: campus);
      final salaries = await getSalaries(month: month, year: year, campus: campus);
      final advances = await getAdvances(month: month, year: year, campus: campus);
      // Let's assume attendance doesn't accurately easily aggregate absents without fetching them all,
      // So we'll return 0 or do a simple fetch if needed.

      double totalPaid = 0;
      for (final s in salaries) {
        if (s.isPaid) totalPaid += s.totalSalary;
      }

      return {
        'total_staff': staffList.$1.length,
        'total_salary_amount': totalPaid,
        'total_absents': 0, // Mocked for now to prevent expensive querying
        'total_advances_count': advances.$1.length,
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
