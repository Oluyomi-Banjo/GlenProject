import 'package:flutter/material.dart';

class Course {
  final int id;
  final String name;
  final String code;
  final int educatorId;
  final DateTime createdAt;
  // New fields for default schedule
  final TimeOfDay? defaultStartTime;
  final TimeOfDay? defaultEndTime;
  final int? defaultDurationMinutes;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.educatorId,
    required this.createdAt,
    this.defaultStartTime,
    this.defaultEndTime,
    this.defaultDurationMinutes,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      educatorId: json['educator_id'],
      createdAt: DateTime.parse(json['created_at']),
      defaultStartTime: json['default_start_time'] != null
          ? _parseTimeOfDay(json['default_start_time'])
          : null,
      defaultEndTime: json['default_end_time'] != null
          ? _parseTimeOfDay(json['default_end_time'])
          : null,
      defaultDurationMinutes: json['default_duration_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'educator_id': educatorId,
      'created_at': createdAt.toIso8601String(),
      'default_start_time':
          defaultStartTime != null ? _formatTimeOfDay(defaultStartTime!) : null,
      'default_end_time':
          defaultEndTime != null ? _formatTimeOfDay(defaultEndTime!) : null,
      'default_duration_minutes': defaultDurationMinutes,
    };
  }

  // Helper method to parse time string to TimeOfDay
  static TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  // Helper method to format TimeOfDay to string
  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Helper getters
  String get formattedDefaultDuration {
    if (defaultDurationMinutes == null) return 'No default duration';
    if (defaultDurationMinutes! < 60) return '${defaultDurationMinutes}m';
    final hours = defaultDurationMinutes! ~/ 60;
    final minutes = defaultDurationMinutes! % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  String get formattedDefaultTimeRange {
    if (defaultStartTime == null || defaultEndTime == null)
      return 'No default schedule';
    final startStr = _formatTimeOfDay(defaultStartTime!);
    final endStr = _formatTimeOfDay(defaultEndTime!);
    return '$startStr - $endStr';
  }

  bool get hasDefaultSchedule =>
      defaultStartTime != null && defaultEndTime != null;

  // Create a copy with updated fields
  Course copyWith({
    int? id,
    String? name,
    String? code,
    int? educatorId,
    DateTime? createdAt,
    TimeOfDay? defaultStartTime,
    TimeOfDay? defaultEndTime,
    int? defaultDurationMinutes,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      educatorId: educatorId ?? this.educatorId,
      createdAt: createdAt ?? this.createdAt,
      defaultStartTime: defaultStartTime ?? this.defaultStartTime,
      defaultEndTime: defaultEndTime ?? this.defaultEndTime,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
    );
  }
}
