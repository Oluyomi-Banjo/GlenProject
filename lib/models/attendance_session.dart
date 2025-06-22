class AttendanceSession {
  final int id;
  final int courseId;
  final bool isOpen;
  final DateTime openedAt;
  final DateTime? closedAt;
  // New fields for time-based session management
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? sessionCode; // Optional: unique code for session

  AttendanceSession({
    required this.id,
    required this.courseId,
    required this.isOpen,
    required this.openedAt,
    this.closedAt,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.sessionCode,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'],
      courseId: json['course_id'],
      isOpen: json['is_open'],
      openedAt: DateTime.parse(json['opened_at']),
      closedAt:
          json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'],
      sessionCode: json['session_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'is_open': isOpen,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'session_code': sessionCode,
    };
  }

  // Helper methods for session state management
  bool get isScheduled => startTime != null;
  bool get hasEnded => closedAt != null;
  bool get isCurrentlyActive {
    final now = DateTime.now();
    if (!isOpen) return false;
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  bool get shouldBeOpen {
    final now = DateTime.now();
    if (startTime == null) return false;
    if (now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  String get sessionStatus {
    final now = DateTime.now();

    if (hasEnded) return 'Ended';
    if (!isOpen && startTime != null && now.isBefore(startTime!)) {
      return 'Scheduled';
    }
    if (isOpen && isCurrentlyActive) return 'Active';
    if (!isOpen) return 'Closed';
    if (endTime != null && now.isAfter(endTime!)) return 'Expired';

    return 'Unknown';
  }

  Duration? get remainingTime {
    if (endTime == null || !isCurrentlyActive) return null;
    final now = DateTime.now();
    if (now.isAfter(endTime!)) return Duration.zero;
    return endTime!.difference(now);
  }

  Duration? get timeUntilStart {
    if (startTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(startTime!)) return Duration.zero;
    return startTime!.difference(now);
  }

  String get formattedDuration {
    if (durationMinutes == null) return 'No duration set';
    if (durationMinutes! < 60) return '${durationMinutes}m';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  String get formattedTimeRange {
    if (startTime == null || endTime == null) return 'No schedule';
    final startStr =
        '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  // Create a copy with updated fields
  AttendanceSession copyWith({
    int? id,
    int? courseId,
    bool? isOpen,
    DateTime? openedAt,
    DateTime? closedAt,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? sessionCode,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      isOpen: isOpen ?? this.isOpen,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionCode: sessionCode ?? this.sessionCode,
    );
  }
}
