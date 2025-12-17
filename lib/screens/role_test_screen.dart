import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleTestScreen extends StatefulWidget {
  const RoleTestScreen({Key? key}) : super(key: key);

  @override
  _RoleTestScreenState createState() => _RoleTestScreenState();
}

class _RoleTestScreenState extends State<RoleTestScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _testResult;
  bool _isLoading = false;

  Future<void> _testRoleSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.testRoleSetup();
      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'error': e.toString(),
          'message': 'Test failed',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Setup Test'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Setup Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Ensure your users table has a "role" column\n'
                        '2. Set roles: "student", "staff", or "admin"\n'
                        '3. Run the test below to verify setup',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testRoleSetup,
                      icon:
                          _isLoading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(Icons.play_arrow),
                      label: Text(_isLoading ? 'Testing...' : 'Full Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Full Test: Tests database connection with RLS policies',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_testResult != null) ...[
                SizedBox(height: 16),
                Card(
                  color:
                      _testResult!['success']
                          ? Colors.green[50]
                          : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _testResult!['success']
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  _testResult!['success']
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _testResult!['success']
                                  ? 'Test Passed'
                                  : 'Test Failed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    _testResult!['success']
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_testResult!['message'] != null)
                          Text(
                            _testResult!['message'],
                            style: TextStyle(fontSize: 14),
                          ),
                        if (_testResult!['error'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Error: ${_testResult!['error']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if (_testResult!['user_id'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'User ID: ${_testResult!['user_id']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_testResult!['email'] != null) ...[
                          Text(
                            'Email: ${_testResult!['email']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_testResult!['role'] != null) ...[
                          Text(
                            'Role: ${_testResult!['role']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (_testResult!['is_staff'] != null) ...[
                          Text(
                            'Is Staff: ${_testResult!['is_staff']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_testResult!['is_admin'] != null) ...[
                          Text(
                            'Is Admin: ${_testResult!['is_admin']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_testResult!['is_student'] != null) ...[
                          Text(
                            'Is Student: ${_testResult!['is_student']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SQL Commands to Run',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '-- Add role column if missing:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT \'student\';',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '-- Set roles for existing users:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'UPDATE users SET role = \'admin\' WHERE email = \'admin@yourcollege.com\';\n'
                              'UPDATE users SET role = \'staff\' WHERE email IN (\'faculty@yourcollege.com\');\n'
                              'UPDATE users SET role = \'student\' WHERE role IS NULL;',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
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
