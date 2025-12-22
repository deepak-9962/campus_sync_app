import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';

class WeeklyAttendanceScreen extends StatefulWidget {
  const WeeklyAttendanceScreen({super.key});

  @override
  State<WeeklyAttendanceScreen> createState() => _WeeklyAttendanceScreenState();
}

class _WeeklyAttendanceScreenState extends State<WeeklyAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  late Future<Map<String, List<Map<String, dynamic>>>> _weeklyAttendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadWeeklyAttendance();
  }

  void _loadWeeklyAttendance() {
    _weeklyAttendanceFuture = _fetchWeeklyAttendance();
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _fetchWeeklyAttendance() async {
    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Extract student ID from email (assuming email format: registration_number@domain.com)
      String studentId;
      if (user.email != null && user.email!.contains('@')) {
        studentId = user.email!.split('@')[0].toUpperCase();
      } else {
        throw Exception('Cannot determine student ID from email');
      }

      return await _attendanceService.getWeeklyPeriodAttendance(studentId);
    } catch (e) {
      print('Error fetching weekly attendance: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weekly Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadWeeklyAttendance();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
            ],
          ),
        ),
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _weeklyAttendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading weekly attendance...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loadWeeklyAttendance();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final weeklyData = snapshot.data!;

            if (weeklyData.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance data available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your weekly schedule or attendance records are not available yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadWeeklyAttendance();
                });
                // Wait for the future to complete
                await _weeklyAttendanceFuture;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: weeklyData.keys.length,
                itemBuilder: (context, index) {
                  final dayName = weeklyData.keys.elementAt(index);
                  final dayAttendance = weeklyData[dayName]!;

                  return _buildDayCard(dayName, dayAttendance);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(
    String dayName,
    List<Map<String, dynamic>> dayAttendance,
  ) {
    // Calculate attendance stats for the day
    int presentCount = 0;
    int totalPeriods = dayAttendance.length;

    for (var period in dayAttendance) {
      if (period['status'] == 'Present') {
        presentCount++;
      }
    }

    double attendancePercentage =
        totalPeriods > 0 ? (presentCount / totalPeriods) * 100 : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header with stats
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$presentCount/$totalPeriods (${attendancePercentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Periods list
            if (dayAttendance.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No classes scheduled for this day',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              Column(
                children:
                    dayAttendance
                        .map((period) => _buildPeriodTile(period))
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTile(Map<String, dynamic> period) {
    final bool isPresent = period['status'] == 'Present';
    final Color statusColor = isPresent ? Colors.green : Colors.red;
    final IconData statusIcon = isPresent ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        color: statusColor.withOpacity(0.05),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'P${period['period_number']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          period['subject_name'] ?? 'Subject not found',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle:
            period['subject_code'] != null
                ? Text(
                  'Code: ${period['subject_code']}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period['status'] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(statusIcon, color: statusColor, size: 20),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
