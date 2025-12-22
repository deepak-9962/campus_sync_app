import 'package:flutter/material.dart';
import '../services/marks_service.dart';

class DBMSMarksScreen extends StatefulWidget {
  const DBMSMarksScreen({super.key});

  @override
  State<DBMSMarksScreen> createState() => _DBMSMarksScreenState();
}

class _DBMSMarksScreenState extends State<DBMSMarksScreen> {
  final MarksService _marksService = MarksService();
  List<Map<String, dynamic>> _marks = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);

    try {
      final marks = await _marksService.getDBMSMarks();
      final stats = await _marksService.getSubjectStatistics(
        'Database Management System',
      );

      setState(() {
        _marks = marks;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading DBMS marks: $error');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMarks {
    if (_searchQuery.isEmpty) return _marks;

    return _marks.where((mark) {
      final regNo = mark['registration_no']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return regNo.contains(query);
    }).toList();
  }

  Color _getMarkColor(int? mark) {
    if (mark == null || mark == -1) return Colors.grey;
    if (mark >= 80) return Colors.green[700]!;
    if (mark >= 60) return Colors.blue[700]!;
    if (mark >= 50) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  String _getGrade(int? mark) {
    if (mark == null || mark == -1) return 'AB';
    if (mark >= 90) return 'A+';
    if (mark >= 80) return 'A';
    if (mark >= 70) return 'B+';
    if (mark >= 60) return 'B';
    if (mark >= 50) return 'C+';
    if (mark >= 40) return 'C';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Management System - Exam Results'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Statistics Card
                  if (_statistics.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Class Statistics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Students',
                                  value: '${_statistics['totalStudents']}',
                                  icon: Icons.people,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Average',
                                  value:
                                      '${_statistics['averageMark']?.toStringAsFixed(1)}',
                                  icon: Icons.trending_up,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Pass Rate',
                                  value:
                                      '${_statistics['passPercentage']?.toStringAsFixed(1)}%',
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Absent',
                                  value: '${_statistics['absentStudents']}',
                                  icon: Icons.cancel,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by registration number...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      onChanged:
                          (value) => setState(() => _searchQuery = value),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results List
                  Expanded(
                    child:
                        _filteredMarks.isEmpty
                            ? Center(
                              child: Text(
                                'No marks found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredMarks.length,
                              itemBuilder: (context, index) {
                                final markData = _filteredMarks[index];
                                final mark = markData['mark'];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getMarkColor(mark),
                                      child: Text(
                                        _getGrade(mark),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Registration: ${markData['registration_no']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Database Management System',
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          (mark != null && mark != -1)
                                              ? '$mark/100'
                                              : 'AB',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _getMarkColor(mark),
                                          ),
                                        ),
                                        if (mark != null && mark != -1)
                                          Text(
                                            '${mark.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMarks,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.refresh, color: colorScheme.onPrimary),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color ?? colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
