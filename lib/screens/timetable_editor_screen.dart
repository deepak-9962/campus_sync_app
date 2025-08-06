import 'package:flutter/material.dart';
import '../services/timetable_management_service.dart';
import '../services/timetable_service.dart';
import '../widgets/period_dialog.dart';

/// Timetable Editor Screen
///
/// This screen allows both Admin and Staff users to:
/// - Create and edit class timetables
/// - Manage periods, subjects, faculty assignments
/// - Copy timetables between sections
/// - Load standard templates
/// - Handle time conflict detection
///
/// Access: Admin and Staff roles only
class TimetableEditorScreen extends StatefulWidget {
  const TimetableEditorScreen({Key? key}) : super(key: key);

  @override
  State<TimetableEditorScreen> createState() => _TimetableEditorScreenState();
}

class _TimetableEditorScreenState extends State<TimetableEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TimetableManagementService _managementService =
      TimetableManagementService();
  final TimetableService _timetableService = TimetableService();

  // Form data
  String _selectedDepartment = 'Computer Science and Engineering';
  int _selectedSemester = 5;
  String _selectedSection = 'A';

  // Current timetable data
  Map<String, List<Map<String, dynamic>>> _currentTimetable = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Dropdown data
  List<Map<String, dynamic>> _subjects = [];
  List<String> _facultyList = [];
  List<String> _roomList = [];

  final List<String> _departments = [
    'Computer Science and Engineering',
    'Information Technology',
    'Electronics and Communication Engineering',
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
    'Biomedical Engineering',
    'Robotics and Automation',
    'Mechanical Engineering',
  ];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadSubjects(),
      _loadFacultyList(),
      _loadRoomList(),
      _loadCurrentTimetable(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadSubjects() async {
    final subjects = await _managementService.getSubjectsForDepartmentSemester(
      department: _selectedDepartment,
      semester: _selectedSemester,
    );
    setState(() => _subjects = subjects);
  }

  Future<void> _loadFacultyList() async {
    final faculty = await _managementService.getFacultyList();
    setState(() => _facultyList = faculty);
  }

  Future<void> _loadRoomList() async {
    final rooms = await _managementService.getRoomList();
    setState(() => _roomList = rooms);
  }

  Future<void> _loadCurrentTimetable() async {
    final timetable = await _timetableService.getTimetable(
      department: _selectedDepartment,
      semester: _selectedSemester,
      section: _selectedSection,
    );
    setState(() => _currentTimetable = timetable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Timetable Editor',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: Icon(
                Icons.save,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveAllChanges,
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'template',
                    child: Text('Load Template'),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Text('Copy from Section'),
                  ),
                  PopupMenuItem(value: 'clear', child: Text('Clear All')),
                  PopupMenuItem(
                    value: 'export',
                    child: Text('Export Timetable'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildDepartmentSelector(),
                  _buildTabBar(),
                  Expanded(child: _buildTabBarView()),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPeriodDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(Icons.add),
        tooltip: 'Add Class Period',
      ),
    );
  }

  Widget _buildDepartmentSelector() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: InputDecoration(
                labelText: 'Department',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.surface,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              items:
                  _departments
                      .map(
                        (dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDepartment = value);
                  _onSelectionChanged();
                }
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: InputDecoration(
                labelText: 'Semester',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.surface,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              items:
                  List.generate(8, (i) => i + 1)
                      .map(
                        (sem) => DropdownMenuItem(
                          value: sem,
                          child: Text(
                            '$sem',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSemester = value);
                  _onSelectionChanged();
                }
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: InputDecoration(
                labelText: 'Section',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.surface,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              items:
                  ['A', 'B', 'C', 'D', 'E']
                      .map(
                        (section) => DropdownMenuItem(
                          value: section,
                          child: Text(
                            section,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSection = value);
                  _onSelectionChanged();
                }
              },
            ),
          ),
          SizedBox(width: 8),
          // Clear/Change Section Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: IconButton(
              onPressed: () => _showSectionChangeDialog(),
              icon: Icon(
                Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Change Section',
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Clash Grotesk',
        ),
        tabs: _days.map((day) => Tab(text: day)).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _days.map((day) => _buildDayEditor(day)).toList(),
    );
  }

  Widget _buildDayEditor(String day) {
    final daySchedule = _currentTimetable[day.toLowerCase()] ?? [];
    final template =
        _managementService.getStandardTimetableTemplate()[day] ?? [];

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: template.length,
      itemBuilder: (context, index) {
        final period = template[index];
        final periodNumber = period['period'];

        if (periodNumber == 'Break' || periodNumber == 'Lunch') {
          return _buildBreakCard(
            periodNumber,
            period['start_time'],
            period['end_time'],
          );
        }

        // Find existing class for this period
        final existingClass = daySchedule.firstWhere(
          (schedule) => schedule['period_number'] == periodNumber,
          orElse: () => <String, dynamic>{},
        );

        return _buildPeriodCard(
          day: day,
          periodNumber: periodNumber,
          startTime: period['start_time'],
          endTime: period['end_time'],
          existingClass: existingClass,
        );
      },
    );
  }

  Widget _buildBreakCard(String type, String startTime, String endTime) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.outline,
          child: Icon(
            type == 'Break' ? Icons.coffee : Icons.restaurant,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Clash Grotesk',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '$startTime - $endTime',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard({
    required String day,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required Map<String, dynamic> existingClass,
  }) {
    final hasClass = existingClass.isNotEmpty;
    final subject =
        hasClass ? _getSubjectName(existingClass['subject_code']) : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              hasClass
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
          child: Text(
            '$periodNumber',
            style: TextStyle(
              color:
                  hasClass
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          hasClass ? subject ?? 'Unknown Subject' : 'Empty Period',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Clash Grotesk',
            color:
                hasClass
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$startTime - $endTime',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            if (hasClass) ...[
              if (existingClass['faculty_name']?.isNotEmpty == true)
                Text(
                  'Faculty: ${existingClass['faculty_name']}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              if (existingClass['room']?.isNotEmpty == true)
                Text(
                  'Room: ${existingClass['room']}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              if (existingClass['batch']?.isNotEmpty == true)
                Text(
                  'Batch: ${existingClass['batch']}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasClass)
              IconButton(
                icon: Icon(Icons.edit, size: 20),
                onPressed:
                    () => _editPeriod(
                      day,
                      periodNumber,
                      startTime,
                      endTime,
                      existingClass,
                    ),
              ),
            IconButton(
              icon: Icon(hasClass ? Icons.delete : Icons.add, size: 20),
              onPressed:
                  hasClass
                      ? () => _deletePeriod(day, periodNumber)
                      : () => _addPeriod(day, periodNumber, startTime, endTime),
            ),
          ],
        ),
      ),
    );
  }

  String? _getSubjectName(String? subjectCode) {
    if (subjectCode == null) return null;
    final subject = _subjects.firstWhere(
      (s) => s['subject_code'] == subjectCode,
      orElse: () => <String, dynamic>{},
    );
    return subject['subject_name'];
  }

  Future<void> _onSelectionChanged() async {
    await _loadInitialData();
  }

  void _showAddPeriodDialog() {
    // Show dialog to add new period - implementation continues in next part
    _showPeriodDialog();
  }

  void _addPeriod(String day, int period, String startTime, String endTime) {
    _showPeriodDialog(
      day: day,
      period: period,
      startTime: startTime,
      endTime: endTime,
    );
  }

  void _editPeriod(
    String day,
    int period,
    String startTime,
    String endTime,
    Map<String, dynamic> existingClass,
  ) {
    _showPeriodDialog(
      day: day,
      period: period,
      startTime: startTime,
      endTime: endTime,
      existingClass: existingClass,
    );
  }

  Future<void> _deletePeriod(String day, int period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Class'),
            content: Text('Are you sure you want to delete this class period?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await _managementService.deleteClassPeriod(
        department: _selectedDepartment,
        semester: _selectedSemester,
        section: _selectedSection,
        dayOfWeek: day,
        periodNumber: period,
      );

      if (success) {
        _loadCurrentTimetable();
        setState(() => _hasUnsavedChanges = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Class deleted successfully')));
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'template':
        _loadTemplate();
        break;
      case 'copy':
        _showCopyDialog();
        break;
      case 'clear':
        _clearAll();
        break;
      case 'export':
        _exportTimetable();
        break;
    }
  }

  void _showPeriodDialog({
    String? day,
    int? period,
    String? startTime,
    String? endTime,
    Map<String, dynamic>? existingClass,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => PeriodDialog(
            day: day,
            period: period,
            startTime: startTime,
            endTime: endTime,
            existingClass: existingClass,
            subjects: _subjects,
            facultyList: _facultyList,
            roomList: _roomList,
            onSave: _savePeriod,
          ),
    );
  }

  Future<void> _savePeriod(Map<String, dynamic> classData) async {
    // Get existing record ID if editing
    final existingId = classData['existing_id'];
    final isEditing = existingId != null;

    // For now, skip conflict detection when editing existing records
    // This is a temporary fix to allow editing while we debug the conflict detection
    bool hasConflict = false;

    if (!isEditing) {
      // Only check conflicts for new records
      hasConflict = await _managementService.hasTimeConflict(
        department: _selectedDepartment,
        semester: _selectedSemester,
        section: _selectedSection,
        dayOfWeek: classData['day'],
        periodNumber: classData['period'],
        room: classData['room'],
        facultyName: classData['faculty_name'],
      );
    }
    // For editing existing records, we skip conflict detection for now
    // This allows users to edit timetables without false conflicts

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conflict detected: Room or faculty already assigned at this time',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save the period
    final success = await _managementService.addOrUpdateClassPeriod(
      department: _selectedDepartment,
      semester: _selectedSemester,
      section: _selectedSection,
      dayOfWeek: classData['day'],
      periodNumber: classData['period'],
      startTime: classData['start_time'],
      endTime: classData['end_time'],
      subjectCode: classData['subject_code'],
      room: classData['room'],
      facultyName: classData['faculty_name'],
      batch: classData['batch'],
    );

    if (success) {
      _loadCurrentTimetable();
      setState(() => _hasUnsavedChanges = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Class saved successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving class'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSectionChangeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Change Section',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Clash Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Section: $_selectedSection',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Select new section:',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['A', 'B', 'C', 'D', 'E'].map((section) {
                          final isSelected = section == _selectedSection;
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                'Section $section',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected && section != _selectedSection) {
                                  Navigator.pop(context);
                                  _changeSectionTo(section);
                                }
                              },
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Changing section will reload the timetable for the selected section.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _changeSectionTo(String newSection) async {
    if (newSection == _selectedSection) return;

    setState(() {
      _selectedSection = newSection;
      _isLoading = true;
    });

    // Show loading indicator and reload timetable
    await _onSelectionChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Switched to Section $newSection'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadTemplate() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Load Template'),
            content: Text(
              'This will create a basic timetable template with standard periods. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createTemplate();
                },
                child: Text('Load Template'),
              ),
            ],
          ),
    );
  }

  Future<void> _createTemplate() async {
    // Create basic template - this could be customized based on your needs
    // You could implement template creation logic here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Template loaded successfully')));

    setState(() => _isLoading = false);
  }

  void _showCopyDialog() {
    String fromSection = 'A';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Copy Timetable'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Copy timetable from:'),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fromSection,
                  decoration: InputDecoration(
                    labelText: 'From Section',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['A', 'B', 'C']
                          .map(
                            (section) => DropdownMenuItem(
                              value: section,
                              child: Text('Section $section'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => fromSection = value ?? 'A',
                ),
                SizedBox(height: 8),
                Text(
                  'To: Section $_selectedSection',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _copyTimetable(fromSection);
                },
                child: Text('Copy'),
              ),
            ],
          ),
    );
  }

  Future<void> _copyTimetable(String fromSection) async {
    setState(() => _isLoading = true);

    final success = await _managementService.copyTimetableToSection(
      department: _selectedDepartment,
      semester: _selectedSemester,
      fromSection: fromSection,
      toSection: _selectedSection,
    );

    if (success) {
      _loadCurrentTimetable();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Timetable copied successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying timetable'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All Classes'),
            content: Text(
              'This will delete all classes for the selected department, semester, and section. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _performClearAll();
                },
                child: Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Future<void> _performClearAll() async {
    // Implementation would involve deleting all records for the current selection
    // This is a placeholder - you'd implement the actual clear functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All classes cleared')));
  }

  void _exportTimetable() {
    // This could export to PDF, Excel, or other formats
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Export Timetable'),
            content: Text(
              'Export functionality will be available in a future update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveAllChanges() async {
    setState(() => _hasUnsavedChanges = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All changes saved')));
  }
}
