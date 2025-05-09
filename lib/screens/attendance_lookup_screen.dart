import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AttendanceLookupScreen extends StatefulWidget {
  const AttendanceLookupScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceLookupScreen> createState() => _AttendanceLookupScreenState();
}

class _AttendanceLookupScreenState extends State<AttendanceLookupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _attendanceService = AttendanceService();

  Map<String, dynamic>? _attendanceData;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableRegistrations = [];
  bool _isLoadingRegistrations = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableRegistrations();
  }

  Future<void> _loadAvailableRegistrations() async {
    setState(() {
      _isLoadingRegistrations = true;
    });

    try {
      final registrations =
          await _attendanceService.getAllRegistrationNumbers();
      setState(() {
        _availableRegistrations = registrations;
        _isLoadingRegistrations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRegistrations = false;
      });
      print('Error loading registration numbers: $e');
    }
  }

  Future<void> _lookupAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attendanceData = null;
    });

    try {
      final result = await _attendanceService.getAttendanceByRegistrationNo(
        _registrationController.text.trim(),
      );

      setState(() {
        _attendanceData = result;
        _isLoading = false;
        if (result == null) {
          _errorMessage =
              'No attendance record found for registration number: ${_registrationController.text.trim()}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _selectRegistration(String regNo) {
    _registrationController.text = regNo;
    _lookupAttendance();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Lookup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _registrationController,
                  decoration: InputDecoration(
                    labelText: 'Registration Number',
                    hintText: 'Enter your registration number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your registration number';
                    }
                    if (value.length < 5) {
                      return 'Registration number seems too short';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _lookupAttendance,
                icon:
                    _isLoading
                        ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.search),
                label: Text(
                  _isLoading ? 'Searching...' : 'Check Attendance',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Show registration lookup guide if no search performed yet
              if (_errorMessage == null && _attendanceData == null)
                _buildRegistrationGuide(),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Record Not Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Make sure you entered the correct registration number, or try one of the available numbers below:',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                      const SizedBox(height: 16),
                      _buildAvailableRegistrationsList(),
                    ],
                  ),
                ),
              if (_attendanceData != null) ...[
                const Divider(height: 40),
                _buildAttendanceCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationGuide() {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Registration Numbers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a registration number from the list below:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildAvailableRegistrationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableRegistrationsList() {
    if (_isLoadingRegistrations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableRegistrations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No registration numbers found in database. Please contact your administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _availableRegistrations.length,
        itemBuilder: (context, index) {
          final reg = _availableRegistrations[index];
          return ListTile(
            dense: true,
            title: Text(reg['registration_no']),
            subtitle: Text(reg['student_name']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              _selectRegistration(reg['registration_no']);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final attendance = _attendanceData!;
    final percentage = attendance['attendance_percentage'];
    final percentageDouble =
        percentage is int ? percentage.toDouble() : percentage;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              attendance['student_name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registration No: ${attendance['registration_no']}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildAttendanceProgress(percentageDouble),
            const SizedBox(height: 24),
            _buildAttendanceDetails(attendance),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceProgress(double percentage) {
    Color progressColor;
    if (percentage < 75) {
      progressColor = Colors.red;
    } else if (percentage < 85) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage / 100),
                duration: const Duration(
                  milliseconds: 2000,
                ), // Slower animation (2 seconds)
                curve: Curves.easeInOut, // Smooth transition curve
                builder:
                    (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      backgroundColor: Colors.grey.shade200,
                    ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: percentage),
              duration: const Duration(
                milliseconds: 2000,
              ), // Match the duration of the progress bar
              curve: Curves.easeInOut,
              builder:
                  (context, value, _) => Column(
                    children: [
                      Text(
                        '${value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: progressColor.withOpacity(0.3)),
          ),
          child: Text(
            percentage < 75
                ? 'Low Attendance! Improvement needed.'
                : percentage < 85
                ? 'Average Attendance! Can improve.'
                : 'Good Attendance!',
            style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(Map<String, dynamic> attendance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailRow(
            'Department',
            attendance['department'] ?? 'Computer Science Engineering',
          ),
          _buildDetailRow(
            'Semester',
            attendance['semester']?.toString() ?? '4',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Total Working Days',
            attendance['total_working_days']?.toString() ?? '0',
            valueColor: Colors.blue,
          ),
          _buildDetailRow(
            'Days Present',
            attendance['days_present']?.toString() ?? '0',
            valueColor: Colors.green,
          ),
          _buildDetailRow(
            'Days Absent',
            attendance['days_absent']?.toString() ?? '0',
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
