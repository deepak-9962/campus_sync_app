import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'faculty/announcement_creation_screen.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String priority;
  final bool isEmergency;
  final DateTime createdAt;
  final String createdBy;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.isEmergency,
    required this.createdAt,
    required this.createdBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      priority: json['priority'],
      isEmergency: json['is_emergency'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }
}

class AnnouncementsScreen extends StatefulWidget {
  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _supabase = Supabase.instance.client;
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _setupRealtimeSubscription();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _announcements =
            (response as List)
                .map((json) => Announcement.fromJson(json))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    _supabase.from('announcements').stream(primaryKey: ['id']).listen((data) {
      setState(() {
        _announcements =
            (data as List).map((json) => Announcement.fromJson(json)).toList();
      });
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'emergency':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<bool> _checkIfStaff() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Debug print user info
      print('User ID: ${user.id}');
      print('User email: ${user.email}');
      
      // Hardcoded check for staff emails based on your database
      // This avoids the RLS infinite recursion issue
      final staffEmails = [
        'deepak5122d@gmail.com',
        'munuswamy@kingsedu.ac.in'
      ];
      
      return staffEmails.contains(user.email);
    } catch (e) {
      print('Error checking staff status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
        backgroundColor: Colors.blue,
        actions: [
          FutureBuilder<bool>(
            future: _checkIfStaff(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementCreationScreen(),
                      ),
                    ).then((_) => _loadAnnouncements());
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _announcements.isEmpty
              ? Center(child: Text('No announcements yet'))
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    announcement.priority,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  announcement.priority.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (announcement.isEmergency)
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.warning, color: Colors.red),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            announcement.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(announcement.content),
                          SizedBox(height: 8),
                          Text(
                            intl.DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(announcement.createdAt),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: FutureBuilder<bool>(
        future: _checkIfStaff(),
        builder: (context, snapshot) {
          // Only show the button for staff members
          if (snapshot.hasData && snapshot.data == true) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.orange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementCreationScreen(),
                        ),
                      ).then((_) => _loadAnnouncements());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CREATE ANNOUNCEMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          // Return empty widget for non-staff users
          return SizedBox.shrink();
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _checkIfStaff(),
        builder: (context, snapshot) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (snapshot.hasData && snapshot.data == true) {
                // Staff member - navigate to announcement creation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementCreationScreen(),
                  ),
                ).then((_) => _loadAnnouncements());
              } else {
                // Regular user - show filter options
                _showFilterOptions(context);
              }
            },
            label: Text(snapshot.hasData && snapshot.data == true 
                ? 'New Announcement' 
                : 'Filter'),
            icon: Icon(snapshot.hasData && snapshot.data == true 
                ? Icons.add 
                : Icons.filter_list),
            backgroundColor: Colors.blue,
          );
        },
      ),
    );
  }
  
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Announcements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text('Emergency Only'),
                onTap: () {
                  // Filter for emergency announcements
                  Navigator.pop(context);
                  _filterAnnouncements('emergency');
                },
              ),
              ListTile(
                leading: Icon(Icons.priority_high, color: Colors.orange),
                title: Text('High Priority'),
                onTap: () {
                  // Filter for high priority announcements
                  Navigator.pop(context);
                  _filterAnnouncements('high');
                },
              ),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Show All'),
                onTap: () {
                  // Reset filters
                  Navigator.pop(context);
                  _loadAnnouncements();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _filterAnnouncements(String priority) async {
    setState(() => _isLoading = true);
    
    try {
      final query = _supabase
          .from('announcements')
          .select();
          
      if (priority == 'emergency') {
        // For emergency filter, show all announcements with is_emergency = true
        final response = await query
            .eq('is_emergency', true)
            .order('created_at', ascending: false);
            
        setState(() {
          _announcements = (response as List)
              .map((json) => Announcement.fromJson(json))
              .toList();
        });
      } else {
        // For other priorities, filter by the priority field
        final response = await query
            .eq('priority', priority)
            .order('created_at', ascending: false);
            
        setState(() {
          _announcements = (response as List)
              .map((json) => Announcement.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error filtering announcements: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error filtering announcements')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
