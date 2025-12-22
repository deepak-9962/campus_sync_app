import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceViewScreen extends StatefulWidget {
  final String department;
  final int semester;

  const AttendanceViewScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  State<AttendanceViewScreen> createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen>
    with TickerProviderStateMixin {
  final _attendanceService = AttendanceService();
  final _supabase = Supabase.instance.client;
  
  // Cache for user names (UUID -> Name)
  final Map<String, String> _userNameCache = {};
  
  // Parent: 0 = Today's (with sub tabs), 1 = Overall
  late TabController _mainTabController;
  // Child (only used when main == 0): 0 = Period, 1 = Daily
  late TabController _todayTabController;

  List<Map<String, dynamic>> _periodAttendance = [];
  List<Map<String, dynamic>> _dailyAttendance = [];
  List<Map<String, dynamic>> _overallAttendance = [];
  // Auto-resolved subject + staff for selected period/date
  String? _resolvedSubjectCode;
  String? _resolvedSubjectName;
  String? _resolvedStaffName;
  bool _isLoading = true;
  String _selectedSection = 'A';
  DateTime _selectedDate = DateTime.now();

  // New state for period browsing
  // Period selection only (subject resolved automatically)
  int? _selectedPeriodNumber;
  final List<int> _periods = const [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _todayTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) return;
      if (mounted) {
        setState(() {});
        if (_mainTabController.index == 1) {
          _loadOverallAttendance();
        } else {
          _loadInitialData();
        }
      }
    });

    _todayTabController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _selectedPeriodNumber ??= _periods.first;
    await _loadAttendanceData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _todayTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily
      var dailyData = await _attendanceService.getDailyAttendanceForDate(
        widget.department,
        widget.semester,
        _selectedSection,
        _selectedDate,
      );

      // Fallback to derived daily view from period records if empty
      if (dailyData.isEmpty) {
        dailyData = await _attendanceService.getDerivedDailyFromPeriods(
          department: widget.department,
          semester: widget.semester,
          section: _selectedSection,
          date: _selectedDate,
        );
      }

      // Resolve subject for chosen period automatically
      List<Map<String, dynamic>> periodData = [];
      if (_selectedPeriodNumber != null) {
        final meta = await _attendanceService.getPeriodClassInfo(
          department: widget.department,
          semester: widget.semester,
          section: _selectedSection,
          date: _selectedDate,
          periodNumber: _selectedPeriodNumber!,
        );
        _resolvedSubjectCode = meta?['subject_code'];
        _resolvedSubjectName = meta?['subject_name'];
        _resolvedStaffName = meta?['staff_name'];
        if (_resolvedSubjectCode != null) {
          periodData = await _attendanceService.getPeriodAttendanceForDate(
            subjectCode: _resolvedSubjectCode!,
            periodNumber: _selectedPeriodNumber!,
            date: _selectedDate,
            department: widget.department,
            semester: widget.semester,
            section: _selectedSection,
          );
        }
      }

      // Collect all marked_by user IDs and fetch their names
      final allData = [...dailyData, ...periodData];
      final markedByIds = allData
          .map((r) => r['marked_by']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      if (markedByIds.isNotEmpty) {
        await _fetchUserNames(markedByIds);
      }

      setState(() {
        _periodAttendance = periodData;
        _dailyAttendance = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
    }
  }

  Future<void> _loadOverallAttendance() async {
    setState(() => _isLoading = true);
    try {
      // Prefer analytics view (includes names). Fallback to summary table if empty.
      var data = await _attendanceService.getOverallAttendanceAnalytics(
        department: widget.department,
        semester: widget.semester,
      );
      if (data.isEmpty) {
        data = await _attendanceService.getAllStudentsAttendance(
          department: widget.department,
          semester: widget.semester,
        );
      }
      setState(() {
        _overallAttendance = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading overall attendance: $e')),
      );
    }
  }

  /// Fetches user names for given UUIDs and caches them
  Future<void> _fetchUserNames(List<String> userIds) async {
    if (userIds.isEmpty) return;
    
    // Filter out already cached IDs
    final idsToFetch = userIds.where((id) => !_userNameCache.containsKey(id)).toList();
    if (idsToFetch.isEmpty) return;
    
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email')
          .inFilter('id', idsToFetch);
      
      for (final user in response) {
        final id = user['id']?.toString() ?? '';
        final name = user['name']?.toString() ?? '';
        final email = user['email']?.toString() ?? '';
        
        // Use name if available, otherwise extract from email
        if (name.isNotEmpty) {
          _userNameCache[id] = name;
        } else if (email.isNotEmpty) {
          // Extract name from email (e.g., john.doe@example.com -> John Doe)
          final emailName = email.split('@').first.replaceAll('.', ' ');
          _userNameCache[id] = emailName.split(' ').map((w) => 
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
          ).join(' ');
        } else {
          _userNameCache[id] = 'Staff';
        }
      }
    } catch (e) {
      debugPrint('Error fetching user names: $e');
    }
  }

  /// Gets user name from cache or returns formatted fallback
  String _getMarkedByName(String? userId) {
    if (userId == null || userId.isEmpty) return '';
    
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }
    
    // Return loading placeholder - will be resolved after fetch
    return 'Loading...';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.department}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [Tab(text: "Today's"), Tab(text: 'Overall')],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.group, color: colorScheme.onPrimary),
            onSelected: (String section) {
              setState(() => _selectedSection = section);
              if (_mainTabController.index == 0) {
                _loadAttendanceData();
              } else {
                _loadOverallAttendance();
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'A', child: Text('Section A')),
                  PopupMenuItem(value: 'B', child: Text('Section B')),
                ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [_buildTodayPane(), _buildOverallPane()],
      ),
    );
  }

  Widget _buildTodayPane() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildDateAndSelectors(
          showPeriodSelectors: _todayTabController.index == 0,
        ),
        TabBar(
          controller: _todayTabController,
          labelColor: colorScheme.primary,
          indicatorColor: colorScheme.primary,
          tabs: const [Tab(text: 'Period'), Tab(text: 'Daily')],
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _todayTabController,
                    children: [
                      _buildPeriodAttendanceTab(),
                      _buildDailyAttendanceTab(),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildOverallPane() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_overallAttendance.isEmpty) {
      return Center(
        child: Text(
          'No overall records for ${widget.department}, Sem ${widget.semester}',
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: Text(
              'Overall Attendance (${_overallAttendance.length} students)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _overallAttendance.length,
            itemBuilder: (context, index) {
              final rec = _overallAttendance[index];
              final pct =
                  (rec['percentage'] ?? rec['attendance_percentage'] ?? 0)
                      .toDouble();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      pct >= 75
                          ? Colors.green[100]
                          : pct >= 50
                          ? Colors.orange[100]
                          : Colors.red[100],
                  child: Text(
                    pct.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(
                  (rec['student_name'] ?? '').toString().trim().isNotEmpty
                      ? '${rec['student_name']}'
                      : rec['registration_no'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(rec['registration_no'] ?? ''),
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          color:
                              pct >= 75
                                  ? Colors.green
                                  : pct >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndSelectors({required bool showPeriodSelectors}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'Section: $_selectedSection',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Change Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: _selectDate,
              ),
            ],
          ),
          if (showPeriodSelectors) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: DropdownButtonFormField<int>(
                value: _selectedPeriodNumber,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    _periods
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p,
                            child: Text('Period $p'),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  setState(() => _selectedPeriodNumber = v);
                  _loadAttendanceData();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodAttendanceTab() {
    if (_selectedPeriodNumber == null) {
      return const Center(child: Text('Select a period'));
    }
    if (_resolvedSubjectCode == null) {
      final colorScheme = Theme.of(context).colorScheme;
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryBar(total: 0, present: 0, absent: 0, attendanceData: []),
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
                  SizedBox(height: 16),
                  Text(
                    'No class scheduled for Period $_selectedPeriodNumber on ${DateFormat('dd MMM').format(_selectedDate)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final int total = _periodAttendance.length;
    final int present =
        _periodAttendance
            .where((r) => (r['is_present'] ?? false) == true)
            .length;
    final int absent = total - present;

    if (_periodAttendance.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryBar(
              total: total,
              present: present,
              absent: absent,
              attendanceData: _periodAttendance,
            ),
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
                  SizedBox(height: 16),
                  Text(
                    'No records for ${DateFormat('dd MMM').format(_selectedDate)}, '
                    'Subject: ${_resolvedSubjectName ?? _resolvedSubjectCode}, '
                    'Period: ${_selectedPeriodNumber ?? '-'}, Sec: $_selectedSection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Subject / Staff header
          if (_resolvedSubjectCode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Icon(Icons.book, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_resolvedSubjectName ?? 'Subject'} (${_resolvedSubjectCode})' +
                          (_resolvedStaffName != null
                              ? ' • ${_resolvedStaffName}'
                              : ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildSummaryBar(
            total: total,
            present: present,
            absent: absent,
            attendanceData: _periodAttendance,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            itemCount: _periodAttendance.length,
            itemBuilder: (context, index) {
              final record = _periodAttendance[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        record['is_present']
                            ? Colors.green[100]
                            : Colors.red[100],
                    child: Icon(
                      record['is_present'] ? Icons.check : Icons.close,
                      color: record['is_present'] ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final rn = (record['registration_no'] ?? '').toString();
                      final nm =
                          ((record['student_name'] ?? '') as String).trim();
                      final showName =
                          nm.isNotEmpty && nm.toUpperCase() != rn.toUpperCase();
                      final text = showName ? '$nm ($rn)' : rn;
                      return Text(
                        text,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reg No: ${record['registration_no']}'),
                      Text(
                        'Subject: ${_resolvedSubjectName ?? _resolvedSubjectCode}',
                      ),
                      Text('Period: ${_selectedPeriodNumber}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record['is_present'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record['is_present'] ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttendanceTab() {
    final int total = _dailyAttendance.length;
    final int present =
        _dailyAttendance
            .where((r) => (r['is_present'] ?? false) == true)
            .length;
    final int absent = total - present;

    if (_dailyAttendance.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryBar(
              total: total,
              present: present,
              absent: absent,
              attendanceData: _dailyAttendance,
            ),
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.today, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
                  SizedBox(height: 16),
                  Text(
                    'No daily attendance records found\nfor this date and section',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryBar(
            total: total,
            present: present,
            absent: absent,
            attendanceData: _dailyAttendance,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            itemCount: _dailyAttendance.length,
            itemBuilder: (context, index) {
              final record = _dailyAttendance[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        record['is_present']
                            ? Colors.blue[100]
                            : Colors.orange[100],
                    child: Icon(
                      record['is_present'] ? Icons.check : Icons.close,
                      color: record['is_present'] ? Colors.blue : Colors.orange,
                    ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final rn = (record['registration_no'] ?? '').toString();
                      final nm =
                          ((record['student_name'] ?? '') as String).trim();
                      final showName =
                          nm.isNotEmpty && nm.toUpperCase() != rn.toUpperCase();
                      final text = showName ? '$nm ($rn)' : rn;
                      return Text(
                        text,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reg No: ${record['registration_no']}'),
                      if (record['marked_at'] != null)
                        Text(
                          'Marked at: ${DateFormat('HH:mm').format(DateTime.parse(record['marked_at']))}',
                        ),
                      if (record['marked_by'] != null)
                        Text('Marked by: ${_getMarkedByName(record['marked_by']?.toString())}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record['is_present'] ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record['is_present'] ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar({
    required int total,
    required int present,
    required int absent,
    List<Map<String, dynamic>>? attendanceData,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryChip(
            label: 'Total',
            value: total.toString(),
            color: colorScheme.onSurface.withOpacity(0.7),
            bg: colorScheme.surfaceContainerHighest,
            onTap: null,
          ),
          _summaryChip(
            label: 'Present',
            value: present.toString(),
            color: Colors.green[800]!,
            bg: Colors.green[100]!,
            onTap:
                attendanceData != null
                    ? () =>
                        _showFilteredAttendance('Present', attendanceData, true)
                    : null,
          ),
          _summaryChip(
            label: 'Absent',
            value: absent.toString(),
            color: Colors.red[800]!,
            bg: Colors.red[100]!,
            onTap:
                attendanceData != null
                    ? () =>
                        _showFilteredAttendance('Absent', attendanceData, false)
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    Widget child = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  void _showFilteredAttendance(
    String title,
    List<Map<String, dynamic>> attendanceData,
    bool isPresent,
  ) {
    final filteredData =
        attendanceData
            .where((record) => (record['is_present'] ?? false) == isPresent)
            .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder:
                (context, scrollController) => Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$title Students (${filteredData.length})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child:
                            filteredData.isEmpty
                                ? Center(
                                  child: Text(
                                    'No $title students',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  itemCount: filteredData.length,
                                  itemBuilder: (context, index) {
                                    final record = filteredData[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              isPresent
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                          child: Icon(
                                            isPresent
                                                ? Icons.check
                                                : Icons.close,
                                            color:
                                                isPresent
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                        ),
                                        title: Builder(
                                          builder: (context) {
                                            final rn =
                                                (record['registration_no'] ??
                                                        '')
                                                    .toString();
                                            final nm =
                                                ((record['student_name'] ?? '')
                                                        as String)
                                                    .trim();
                                            final showName =
                                                nm.isNotEmpty &&
                                                nm.toUpperCase() !=
                                                    rn.toUpperCase();
                                            final text =
                                                showName ? '$nm ($rn)' : rn;
                                            return Text(
                                              text,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                        subtitle: Text(
                                          'Reg No: ${record['registration_no']}',
                                        ),
                                        trailing: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isPresent
                                                    ? Colors.green
                                                    : Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isPresent ? 'Present' : 'Absent',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
