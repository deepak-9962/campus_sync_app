import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';

class DailyAttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String section;

  const DailyAttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
    required this.section,
  }) : super(key: key);

  @override
  _DailyAttendanceScreenState createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<String, bool> _attendance = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final service = AttendanceService();
    final students = await service.getAllRegistrationNumbers();
    final filtered =
        students
            .where(
              (s) =>
                  (s['department'] == widget.department) &&
                  (s['semester'] == widget.semester) &&
                  (s['section'] == widget.section),
            )
            .toList();
    setState(() {
      _students = filtered;
      _attendance = {
        for (var s in filtered) s['registration_no'] as String: true,
      };
      _isLoading = false;
    });
  }

  void _markAll(bool present) {
    setState(() {
      for (var reg in _attendance.keys) {
        _attendance[reg] = present;
      }
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Attendance')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department: ${widget.department}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Semester: ${widget.semester}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Section: ${widget.section}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        IconButton(
                          icon: Icon(Icons.calendar_today, size: 20),
                          onPressed: _pickDate,
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () => _markAll(true),
                          child: const Text('Mark All Present'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _markAll(false),
                          child: const Text('Mark All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final student = _students[idx];
                          final reg = student['registration_no'] as String;
                          final name = student['student_name'] as String;
                          final present = _attendance[reg] ?? true;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${idx + 1}')),
                            title: Text(name),
                            subtitle: Text(reg),
                            trailing: Switch(
                              value: present,
                              onChanged: (val) {
                                setState(() {
                                  _attendance[reg] = val;
                                });
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                            tileColor:
                                present ? Colors.green[50] : Colors.red[50],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Present: ${_attendance.values.where((v) => v).length}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Absent: ${_attendance.values.where((v) => !v).length}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${_students.length}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Attendance saved locally!')),
                        );
                      },
                      icon: Icon(Icons.save),
                      label: Text('Submit Attendance'),
                    ),
                  ],
                ),
              ),
    );
  }
}
