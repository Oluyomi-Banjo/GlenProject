import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/models/course.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/models/user.dart';
import 'package:attendance_app/utils/constants.dart';
import 'package:attendance_app/utils/network_utils.dart';

class CourseService extends ChangeNotifier {
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCourses(String token, {String? search}) async {
    // Set loading state but don't notify during build
    _isLoading = true;
    _error = null;
    // Notify listeners after current build completes
    Future.microtask(() => notifyListeners());

    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.courses}';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await NetworkUtils.authenticatedGet(url, token);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _courses = data.map((json) => Course.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch courses: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      // Notify listeners after data is loaded
      Future.microtask(() => notifyListeners());
    }
  }

  Future<Map<String, dynamic>> createCourse(
    String token,
    String name,
    String code,
    String passkey, {
    TimeOfDay? defaultStartTime,
    TimeOfDay? defaultEndTime,
    int? defaultDurationMinutes,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'name': name,
        'code': code,
        'passkey': passkey,
      };

      // Add schedule information if provided
      if (defaultStartTime != null) {
        payload['default_start_time'] =
            '${defaultStartTime.hour.toString().padLeft(2, '0')}:${defaultStartTime.minute.toString().padLeft(2, '0')}';
      }
      if (defaultEndTime != null) {
        payload['default_end_time'] =
            '${defaultEndTime.hour.toString().padLeft(2, '0')}:${defaultEndTime.minute.toString().padLeft(2, '0')}';
      }
      if (defaultDurationMinutes != null) {
        payload['default_duration_minutes'] = defaultDurationMinutes;
      }

      final response = await NetworkUtils.authenticatedPost(
        '${ApiConstants.baseUrl}${ApiConstants.courses}',
        token,
        payload,
      );

      if (response.statusCode == 200) {
        final course = Course.fromJson(jsonDecode(response.body));
        _courses.add(course);
        notifyListeners();
        return {'success': true, 'course': course};
      } else {
        return {
          'success': false,
          'message':
              'Failed to create course: ${jsonDecode(response.body)['detail']}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> enrollInCourse(
      String token, int courseId, String passkey) async {
    try {
      if (kDebugMode) {
        print('Enrolling in course $courseId with passkey $passkey');
      }

      final Map<String, dynamic> payload = {
        'course_id': courseId,
        'passkey': passkey,
      };

      final response = await NetworkUtils.authenticatedPost(
        '${ApiConstants.baseUrl}${ApiConstants.enrollment}',
        token,
        payload,
      );

      if (kDebugMode) {
        print('Enrollment response status: ${response.statusCode}');
        print('Enrollment response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Failed to enroll in course',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enrolling in course: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<List<AttendanceSession>> getCourseSessions(
      String token, int courseId) async {
    try {
      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.sessions}/course/$courseId',
        token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AttendanceSession.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch sessions: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sessions: $e');
      }
      return [];
    }
  }

  Future<AttendanceSession?> createAttendanceSession(
    String token,
    int courseId, {
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? sessionCode,
  }) async {
    try {
      if (kDebugMode) {
        print('Creating attendance session for course ID: $courseId');
      }

      final Map<String, dynamic> payload = {
        'course_id': courseId,
      };

      // Add time-based parameters if provided
      if (startTime != null) {
        payload['start_time'] = startTime.toIso8601String();
      }
      if (endTime != null) {
        payload['end_time'] = endTime.toIso8601String();
      }
      if (durationMinutes != null) {
        payload['duration_minutes'] = durationMinutes;
      }
      if (sessionCode != null) {
        payload['session_code'] = sessionCode;
      }

      if (kDebugMode) {
        print('Session payload: $payload');
      }

      final response = await NetworkUtils.authenticatedPost(
        '${ApiConstants.baseUrl}${ApiConstants.sessions}',
        token,
        payload,
      );

      if (kDebugMode) {
        print('Create session response status: ${response.statusCode}');
        print('Create session response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return AttendanceSession.fromJson(responseData);
      } else {
        if (kDebugMode) {
          print('Failed to create session: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating session: $e');
      }
      rethrow; // Rethrow to allow proper error handling in the UI
    }
  }

  // Helper method to create a session with course default schedule
  Future<AttendanceSession?> createAttendanceSessionWithDefaults(
    String token,
    Course course, {
    DateTime? customStartTime,
    DateTime? customEndTime,
    int? customDurationMinutes,
    String? sessionCode,
  }) async {
    DateTime? startTime = customStartTime;
    DateTime? endTime = customEndTime;
    int? durationMinutes = customDurationMinutes;

    // Use course defaults if custom values not provided
    if (startTime == null && course.defaultStartTime != null) {
      final now = DateTime.now();
      startTime = DateTime(
        now.year,
        now.month,
        now.day,
        course.defaultStartTime!.hour,
        course.defaultStartTime!.minute,
      );
    }

    if (endTime == null && course.defaultEndTime != null) {
      final now = DateTime.now();
      endTime = DateTime(
        now.year,
        now.month,
        now.day,
        course.defaultEndTime!.hour,
        course.defaultEndTime!.minute,
      );
    }

    if (durationMinutes == null && course.defaultDurationMinutes != null) {
      durationMinutes = course.defaultDurationMinutes;
    }

    // If we still don't have a duration, calculate from start/end times
    if (durationMinutes == null && startTime != null && endTime != null) {
      durationMinutes = endTime.difference(startTime).inMinutes;
    }

    return createAttendanceSession(
      token,
      course.id,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      sessionCode: sessionCode,
    );
  }

  Future<AttendanceSession?> updateAttendanceSession(
      String token, int sessionId, bool isOpen) async {
    try {
      if (kDebugMode) {
        print('Updating session $sessionId to isOpen=$isOpen');
      }

      // Create the payload
      final Map<String, dynamic> payload = {
        'is_open': isOpen,
      };

      if (kDebugMode) {
        print('Update session payload: $payload');
      }

      final response = await NetworkUtils.authenticatedPatch(
        '${ApiConstants.baseUrl}${ApiConstants.sessions}/$sessionId',
        token,
        payload,
      );

      if (kDebugMode) {
        print('Update session response status: ${response.statusCode}');
        print('Update session response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AttendanceSession.fromJson(responseData);
      } else {
        if (kDebugMode) {
          print('Failed to update session: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception('Failed to update session: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating session: $e');
      }
      rethrow; // Rethrow to allow proper error handling in the UI
    }
  }

  Future<String?> exportAttendance(String token, int courseId) async {
    try {
      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.attendance}/export/course/$courseId',
        token,
      );

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        throw Exception('Failed to export attendance: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting attendance: $e');
      }
      return null;
    }
  }

  // Get courses the student is enrolled in
  Future<void> fetchEnrolledCourses(String token, {String? search}) async {
    // Set loading state but don't notify during build
    _isLoading = true;
    _error = null;
    // Notify listeners after current build completes
    Future.microtask(() => notifyListeners());

    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.courses}/enrolled';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await NetworkUtils.authenticatedGet(url, token);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _courses = data.map((json) => Course.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch enrolled courses: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      // Notify listeners after data is loaded
      Future.microtask(() => notifyListeners());
    }
  }

  // Get list of students enrolled in a course
  Future<List<User>> getEnrolledStudents(String token, int courseId) async {
    try {
      if (kDebugMode) {
        print('Fetching enrolled students for course ID: $courseId');
      }

      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.courses}/$courseId/students',
        token,
      );

      if (kDebugMode) {
        print('Get enrolled students response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch enrolled students: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception(
            'Failed to fetch enrolled students: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching enrolled students: $e');
      }
      throw Exception('Error fetching enrolled students: $e');
    }
  }

  // Get attendance records for a specific session
  Future<List<Map<String, dynamic>>> getSessionAttendance(
      String token, int sessionId) async {
    try {
      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.attendance}/sessions/$sessionId/records',
        token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
            'Failed to fetch session attendance: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching session attendance: $e');
      }
      return [];
    }
  }

  // Get course details including metadata
  Future<Map<String, dynamic>> getCourseDetails(
      String token, int courseId) async {
    try {
      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.courses}/$courseId',
        token,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch course details: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching course details: $e');
      }
      throw Exception('Error fetching course details: $e');
    }
  }

  // Update course details
  Future<Map<String, dynamic>> updateCourse(
    String token,
    int courseId, {
    String? name,
    String? code,
    String? passkey,
    TimeOfDay? defaultStartTime,
    TimeOfDay? defaultEndTime,
    int? defaultDurationMinutes,
  }) async {
    try {
      final Map<String, dynamic> payload = {};

      if (name != null) payload['name'] = name;
      if (code != null) payload['code'] = code;
      if (passkey != null) payload['passkey'] = passkey;

      if (defaultStartTime != null) {
        payload['default_start_time'] =
            '${defaultStartTime.hour.toString().padLeft(2, '0')}:${defaultStartTime.minute.toString().padLeft(2, '0')}';
      }
      if (defaultEndTime != null) {
        payload['default_end_time'] =
            '${defaultEndTime.hour.toString().padLeft(2, '0')}:${defaultEndTime.minute.toString().padLeft(2, '0')}';
      }
      if (defaultDurationMinutes != null) {
        payload['default_duration_minutes'] = defaultDurationMinutes;
      }

      final response = await NetworkUtils.authenticatedPatch(
        '${ApiConstants.baseUrl}${ApiConstants.courses}/$courseId',
        token,
        payload,
      );

      if (response.statusCode == 200) {
        final updatedCourse = Course.fromJson(jsonDecode(response.body));

        // Update the course in the local list
        final index = _courses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _courses[index] = updatedCourse;
          notifyListeners();
        }

        return {'success': true, 'course': updatedCourse};
      } else {
        return {
          'success': false,
          'message':
              'Failed to update course: ${jsonDecode(response.body)['detail'] ?? response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete a course
  Future<Map<String, dynamic>> deleteCourse(String token, int courseId) async {
    try {
      final response = await NetworkUtils.authenticatedDelete(
        '${ApiConstants.baseUrl}${ApiConstants.courses}/$courseId',
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove the course from the local list
        _courses.removeWhere((course) => course.id == courseId);
        notifyListeners();

        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete course: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get attendance stats for a course
  Future<Map<String, dynamic>> getCourseAttendanceStats(
      String token, int courseId) async {
    try {
      final response = await NetworkUtils.authenticatedGet(
        '${ApiConstants.baseUrl}${ApiConstants.attendance}/stats/course/$courseId',
        token,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch attendance stats: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching attendance stats: $e');
      }
      throw Exception('Error fetching attendance stats: $e');
    }
  }
}
