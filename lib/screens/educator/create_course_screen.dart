import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:attendance_app/services/course_service.dart';
import 'package:attendance_app/utils/constants.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passKeyController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Schedule fields
  TimeOfDay? _defaultStartTime;
  TimeOfDay? _defaultEndTime;
  int _defaultDurationMinutes = 60; // Default 1 hour

  @override
  void initState() {
    super.initState();
    // Set default times
    _defaultStartTime = const TimeOfDay(hour: 9, minute: 0); // 9:00 AM
    _defaultEndTime = const TimeOfDay(hour: 10, minute: 0); // 10:00 AM
    _durationController.text = _defaultDurationMinutes.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _passKeyController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _updateEndTimeFromDuration() {
    if (_defaultStartTime != null && _durationController.text.isNotEmpty) {
      final duration = int.tryParse(_durationController.text) ?? 60;
      final startDateTime = DateTime(
          2024, 1, 1, _defaultStartTime!.hour, _defaultStartTime!.minute);
      final endDateTime = startDateTime.add(Duration(minutes: duration));

      setState(() {
        _defaultEndTime =
            TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
        _defaultDurationMinutes = duration;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _defaultStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _defaultStartTime = picked;
      });
      _updateEndTimeFromDuration();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _defaultEndTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null && _defaultStartTime != null) {
      // Calculate duration
      final startMinutes =
          _defaultStartTime!.hour * 60 + _defaultStartTime!.minute;
      final endMinutes = picked.hour * 60 + picked.minute;
      final duration = endMinutes - startMinutes;

      if (duration > 0) {
        setState(() {
          _defaultEndTime = picked;
          _defaultDurationMinutes = duration;
          _durationController.text = duration.toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
    }
  }

  Future<void> _createCourse() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final courseService = Provider.of<CourseService>(context, listen: false);

      if (authService.token != null) {
        final result = await courseService.createCourse(
          authService.token!,
          _nameController.text.trim(),
          _codeController.text.trim(),
          _passKeyController.text,
          defaultStartTime: _defaultStartTime,
          defaultEndTime: _defaultEndTime,
          defaultDurationMinutes: _defaultDurationMinutes,
        );

        if (result['success']) {
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating course: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new course for your students to enroll in.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Course Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  prefixIcon: Icon(Icons.school),
                  hintText: 'e.g., Introduction to Computer Science',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course Code Field
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  prefixIcon: Icon(Icons.code),
                  hintText: 'e.g., CS101',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Passkey Field
              TextFormField(
                controller: _passKeyController,
                decoration: const InputDecoration(
                  labelText: 'Enrollment Passkey',
                  prefixIcon: Icon(Icons.vpn_key),
                  hintText: 'Create a passkey for students to enroll',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an enrollment passkey';
                  }
                  if (value.length < 4) {
                    return 'Passkey must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Default Schedule Section
              const Text(
                'Default Class Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set default timing for attendance sessions. This can be modified for individual sessions.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Time Selection Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectStartTime,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeOfDay(_defaultStartTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectEndTime,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeOfDay(_defaultEndTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration Field
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer),
                  hintText: 'e.g., 60',
                  suffixText: 'min',
                ),
                onChanged: (value) {
                  _updateEndTimeFromDuration();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Please enter a valid duration';
                  }
                  if (duration > 480) {
                    // 8 hours max
                    return 'Duration cannot exceed 8 hours (480 minutes)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withAlpha(26), // 0.1 * 255 = ~26
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createCourse,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Course'),
              ),

              const SizedBox(height: 16),

              // Schedule Summary
              if (_defaultStartTime != null && _defaultEndTime != null)
                Card(
                  color: Colors.blue.withAlpha(13), // 0.05 * 255 = ~13
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Start: ${_formatTimeOfDay(_defaultStartTime)}'),
                        Text('End: ${_formatTimeOfDay(_defaultEndTime)}'),
                        Text('Duration: $_defaultDurationMinutes minutes'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
