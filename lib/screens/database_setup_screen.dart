import 'package:flutter/material.dart';
import '../services/data_setup_service.dart';

class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  final _dataSetupService = DataSetupService();
  bool _isLoading = false;
  bool _setupComplete = false;
  String _statusMessage = '';
  List<String> _logMessages = [];

  Future<void> _setupDatabase() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _setupComplete = false;
      _statusMessage = 'Validating database structure...';
      _logMessages = [];
    });

    _addLog('Starting database setup process...');

    // First validate structure
    bool isValid = await _dataSetupService.validateDatabaseStructure();

    if (!isValid) {
      setState(() {
        _isLoading = false;
        _setupComplete = false;
        _statusMessage =
            'Database validation failed. Please check your Supabase configuration.';
      });
      _addLog(
        '❌ Database validation failed. Please make sure the student_attendance table exists.',
      );
      return;
    }

    _addLog('✅ Database structure validation successful');
    _addLog('Starting data population...');

    // Then populate the data
    setState(() {
      _statusMessage = 'Populating database with sample data...';
    });

    try {
      await _dataSetupService.setupAttendanceData();

      setState(() {
        _isLoading = false;
        _setupComplete = true;
        _statusMessage = 'Database setup complete!';
      });

      _addLog('✅ Database setup complete');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _setupComplete = false;
        _statusMessage = 'Error setting up database: $e';
      });

      _addLog('❌ Error during setup: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setup Attendance Database',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will populate your Supabase student_attendance table with sample data. '
                      'This is useful for testing and demonstration purposes.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _setupDatabase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      child:
                          _isLoading
                              ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Setting up database...'),
                                ],
                              )
                              : const Text('Setup Database'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _setupComplete ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Setup Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child:
                    _logMessages.isEmpty
                        ? const Center(
                          child: Text(
                            'No log messages yet. Click "Setup Database" to start.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _logMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _logMessages[index],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color:
                                      _logMessages[index].contains('❌')
                                          ? Colors.red
                                          : _logMessages[index].contains('✅')
                                          ? Colors.green
                                          : null,
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            if (_setupComplete)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Attendance Screen'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
