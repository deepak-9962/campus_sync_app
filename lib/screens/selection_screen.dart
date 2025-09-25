import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  final List<String> _departments = const [
    'Computer Science and Engineering',
    'Information Technology',
    'Electronics and Communication Engineering',
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
    'Biomedical Engineering',
    'Robotics and Automation',
    'Mechanical Engineering',
  ];
  final List<int> _semesters = List.generate(8, (i) => i + 1);

  late String _selectedDepartment;
  late int _selectedSemester;

  @override
  void initState() {
    super.initState();
    _selectedDepartment = _departments.first;
    _selectedSemester = 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Context'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Choose your Department and Semester',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: _departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDepartment = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
              ),
              items: _semesters
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSemester = v!),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userName: userEmail,
                        department: _selectedDepartment,
                        semester: _selectedSemester,
                      ),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
