import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pdf_upload_screen.dart';

class AnnouncementCreationScreen extends StatefulWidget {
  @override
  _AnnouncementCreationScreenState createState() =>
      _AnnouncementCreationScreenState();
}

class _AnnouncementCreationScreenState
    extends State<AnnouncementCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedPriority = 'medium';
  bool _isEmergency = false;
  final _supabase = Supabase.instance.client;

  Future<void> _createAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to create announcements')),
          );
          return;
        }

        final announcement = {
          'title': _titleController.text,
          'content': _contentController.text,
          'priority': _selectedPriority,
          'is_emergency': _isEmergency,
          'created_by': user.id,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert the announcement
        final response = await _supabase
            .from('announcements')
            .insert(announcement)
            .select()
            .single();

        // Send real-time notification to all subscribers
        await _supabase.rpc('notify_new_announcement', params: {
          'announcement_id': response['id'],
          'title': _titleController.text,
          'content': _contentController.text,
          'priority': _selectedPriority,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement created successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating announcement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Announcement'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        items: [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(
                            value: 'emergency',
                            child: Text('Emergency'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedPriority = value!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          'Emergency Announcement',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'This will send immediate notifications to all users',
                        ),
                        value: _isEmergency,
                        onChanged: (value) =>
                            setState(() => _isEmergency = value),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfUploadScreen(
                              department: 'Computer Science Engineering',
                              semester: 4,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.upload_file),
                      label: Text('Upload PDF Resource'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Publish Announcement',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
