import 'package:flutter/material.dart';

class PeriodDialog extends StatefulWidget {
  final String? day;
  final int? period;
  final String? startTime;
  final String? endTime;
  final Map<String, dynamic>? existingClass;
  final List<Map<String, dynamic>> subjects;
  final List<String> facultyList;
  final List<String> roomList;
  final Function(Map<String, dynamic>) onSave;

  const PeriodDialog({
    Key? key,
    this.day,
    this.period,
    this.startTime,
    this.endTime,
    this.existingClass,
    required this.subjects,
    required this.facultyList,
    required this.roomList,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<PeriodDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDay;
  int? _selectedPeriod;
  String? _selectedSubject;
  String? _selectedFaculty;
  String? _selectedRoom;
  String? _selectedBatch;
  String _startTime = '';
  String _endTime = '';

  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  final List<int> _periods = [1, 2, 3, 4, 5, 6];
  final List<String> _batches = ['', 'B1', 'B2', 'B3'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _selectedDay = widget.day;
    _selectedPeriod = widget.period;
    _startTime = widget.startTime ?? '';
    _endTime = widget.endTime ?? '';

    if (widget.existingClass != null) {
      final existing = widget.existingClass!;
      _selectedSubject = existing['subject_code'];
      _selectedFaculty = existing['faculty_name'];
      _selectedRoom = existing['room'];
      _selectedBatch = existing['batch'] ?? '';

      _facultyController.text = _selectedFaculty ?? '';
      _roomController.text = _selectedRoom ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingClass != null;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        isEditing ? 'Edit Class Period' : 'Add Class Period',
        style: TextStyle(
          fontFamily: 'Clash Grotesk',
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day Selection
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Day',
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
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items:
                      _days
                          .map<DropdownMenuItem<String>>(
                            (day) => DropdownMenuItem<String>(
                              value: day,
                              child: Text(
                                day,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedDay = value),
                  validator:
                      (value) => value == null ? 'Please select a day' : null,
                ),
                SizedBox(height: 16),

                // Period and Time Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedPeriod,
                        decoration: InputDecoration(
                          labelText: 'Period',
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
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        items:
                            _periods
                                .map<DropdownMenuItem<int>>(
                                  (period) => DropdownMenuItem<int>(
                                    value: period,
                                    child: Text(
                                      'Period $period',
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _selectedPeriod = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _startTime,
                        decoration: InputDecoration(
                          labelText: 'Start Time',
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
                          hintText: 'HH:MM',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onChanged: (value) => _startTime = value,
                        validator:
                            (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _endTime,
                        decoration: InputDecoration(
                          labelText: 'End Time',
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
                          hintText: 'HH:MM',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onChanged: (value) => _endTime = value,
                        validator:
                            (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Subject Selection
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Subject',
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
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items:
                      widget.subjects
                          .map<DropdownMenuItem<String>>(
                            (subject) => DropdownMenuItem<String>(
                              value: subject['subject_code'],
                              child: Text(
                                '${subject['subject_name']} (${subject['subject_code']})',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;

                      // Auto-populate faculty based on selected subject
                      if (value != null) {
                        final selectedSubjectData = widget.subjects.firstWhere(
                          (subject) => subject['subject_code'] == value,
                          orElse: () => {},
                        );

                        if (selectedSubjectData.isNotEmpty &&
                            selectedSubjectData['faculty_name'] != null &&
                            selectedSubjectData['faculty_name']
                                .toString()
                                .isNotEmpty) {
                          _selectedFaculty =
                              selectedSubjectData['faculty_name'];
                          _facultyController.text = _selectedFaculty ?? '';
                        }
                      }
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a subject' : null,
                ),
                SizedBox(height: 16),

                // Faculty Selection with Autocomplete
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _facultyController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return widget.facultyList;
                    }
                    return widget.facultyList.where(
                      (faculty) => faculty.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (value) {
                    _selectedFaculty = value;
                    _facultyController.text = value;
                  },
                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Faculty Name',
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
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onChanged: (value) => _selectedFaculty = value,
                    );
                  },
                ),
                SizedBox(height: 16),

                // Room Selection with Autocomplete
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _roomController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return widget.roomList;
                    }
                    return widget.roomList.where(
                      (room) => room.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (value) {
                    _selectedRoom = value;
                    _roomController.text = value;
                  },
                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Room',
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
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onChanged: (value) => _selectedRoom = value,
                    );
                  },
                ),
                SizedBox(height: 16),

                // Batch Selection
                DropdownButtonFormField<String>(
                  value: _selectedBatch,
                  decoration: InputDecoration(
                    labelText: 'Batch (Optional)',
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
                    helperText:
                        'Leave empty for full class, select B1/B2 for lab batches',
                    helperStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items:
                      _batches
                          .map<DropdownMenuItem<String>>(
                            (batch) => DropdownMenuItem<String>(
                              value: batch,
                              child: Text(
                                batch.isEmpty ? 'Full Class' : batch,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedBatch = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveClass,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveClass() {
    if (_formKey.currentState!.validate()) {
      final classData = {
        'day': _selectedDay,
        'period': _selectedPeriod,
        'start_time': _startTime,
        'end_time': _endTime,
        'subject_code': _selectedSubject,
        'faculty_name': _selectedFaculty ?? '',
        'room': _selectedRoom ?? '',
        'batch': _selectedBatch ?? '',
      };

      widget.onSave(classData);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _facultyController.dispose();
    _roomController.dispose();
    super.dispose();
  }
}
