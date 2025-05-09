import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _announcements = [];
  String? _errorMessage;
  bool _isAdmin = false; // Track if current user is admin

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    _checkAdminStatus(); // Check if user is admin

    // TEMPORARY: Force enable admin for testing - REMOVE IN PRODUCTION
    setState(() {
      _isAdmin = true;
    });
    debugPrint('OVERRIDE: Admin status forced to true for testing');
  }

  // Check if the current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      debugPrint('Checking admin status for user: ${user?.id}');

      if (user != null) {
        try {
          // First, let's check if the profiles table exists and what fields it has
          final profilesCheck = await _supabase
              .from('profiles')
              .select('*')
              .limit(1);
          debugPrint('Profiles table first row: $profilesCheck');

          // Now try to get the current user's profile
          final userData =
              await _supabase
                  .from('profiles')
                  .select('*') // Select all fields to see what's available
                  .eq('id', user.id)
                  .single();

          debugPrint('User profile data: $userData');

          // Check multiple possible admin field names
          bool isAdmin = false;
          if (userData.containsKey('is_admin')) {
            isAdmin = userData['is_admin'] == true;
            debugPrint(
              'is_admin field found with value: ${userData['is_admin']}',
            );
          } else if (userData.containsKey('admin')) {
            isAdmin = userData['admin'] == true;
            debugPrint('admin field found with value: ${userData['admin']}');
          } else if (userData.containsKey('role')) {
            isAdmin =
                userData['role'] == 'admin' || userData['role'] == 'faculty';
            debugPrint('role field found with value: ${userData['role']}');
          } else if (userData.containsKey('user_type')) {
            isAdmin =
                userData['user_type'] == 'admin' ||
                userData['user_type'] == 'faculty';
            debugPrint(
              'user_type field found with value: ${userData['user_type']}',
            );
          }

          // For testing purposes, let's also check if the email contains certain domains
          final email = user.email?.toLowerCase() ?? '';
          if (email.contains('faculty') ||
              email.contains('admin') ||
              email.contains('teacher')) {
            debugPrint('Email suggests admin status: $email');
            isAdmin = true;
          }

          setState(() {
            _isAdmin = isAdmin;
          });

          debugPrint('Final admin status set to: $_isAdmin');
        } catch (e) {
          debugPrint('Error fetching user profile: $e');

          // Fallback: check if email contains faculty/admin keywords
          final email = user.email?.toLowerCase() ?? '';
          if (email.contains('faculty') ||
              email.contains('admin') ||
              email.contains('teacher')) {
            debugPrint('Fallback: Email suggests admin status: $email');
            setState(() {
              _isAdmin = true;
            });
          }
        }
      } else {
        debugPrint('No logged in user found');
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  // Create a new announcement
  void _createAnnouncement() {
    // These will be used in the form
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'medium';
    bool isEmergency = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Create Announcement'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: contentController,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        const Text('Priority:'),
                        DropdownButton<String>(
                          value: priority,
                          isExpanded: true,
                          items:
                              ['low', 'medium', 'high', 'emergency']
                                  .map(
                                    (String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                priority = newValue;
                                // Auto-set emergency flag for emergency priority
                                if (newValue == 'emergency') {
                                  isEmergency = true;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text('Mark as Emergency'),
                          value: isEmergency,
                          onChanged: (bool? value) {
                            setState(() {
                              isEmergency = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Validate inputs
                        if (titleController.text.isEmpty ||
                            contentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }

                        try {
                          // Insert the new announcement
                          await _supabase.from('announcements').insert({
                            'title': titleController.text.trim(),
                            'content': contentController.text.trim(),
                            'priority': priority,
                            'is_emergency': isEmergency,
                            'created_by': _supabase.auth.currentUser?.id,
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          // Close dialog and refresh announcements
                          if (mounted) {
                            Navigator.pop(context);
                            _fetchAnnouncements();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Announcement created successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating announcement: $e'),
                            ),
                          );
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('announcements')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _announcements = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading announcements: $e';
        _isLoading = false;
      });
    }
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get priority icon
  IconData _getPriorityIcon(String priority, bool isEmergency) {
    if (isEmergency) return Icons.warning_amber_rounded;

    switch (priority) {
      case 'low':
        return Icons.info_outline;
      case 'medium':
        return Icons.campaign_outlined;
      case 'high':
        return Icons.priority_high_outlined;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.announcement_outlined;
    }
  }

  // Format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnnouncements,
          ),
        ],
      ),
      floatingActionButton:
          _isAdmin
              ? FloatingActionButton.extended(
                onPressed: _createAnnouncement,
                icon: const Icon(Icons.add),
                label: const Text('Announcement'),
                tooltip: 'Create Announcement',
              )
              : null,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAnnouncements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _announcements.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No announcements yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchAnnouncements,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchAnnouncements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = _announcements[index];
                    final bool isEmergency =
                        announcement['is_emergency'] ?? false;
                    final String priority =
                        announcement['priority'] ?? 'medium';
                    final Color priorityColor = _getPriorityColor(priority);
                    final String createdAt = _formatDate(
                      announcement['created_at'],
                    );

                    // Simplified creator name since we no longer have the users join
                    final String creatorName =
                        "Faculty Member"; // Default value

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: isEmergency ? 4 : 2,
                      shape:
                          isEmergency
                              ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red, width: 2),
                              )
                              : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isEmergency
                                      ? Colors.red.withOpacity(0.1)
                                      : priorityColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(priority, isEmergency),
                                  color: priorityColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEmergency
                                      ? 'EMERGENCY'
                                      : priority.toUpperCase(),
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  announcement['content'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Posted by $creatorName',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
