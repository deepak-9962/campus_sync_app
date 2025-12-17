import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _announcements = [];
  String? _errorMessage;
  bool _isStaffOrAdmin = false; // Track if current user is staff or admin

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    _checkRoleStatus();
  }

  Future<void> _checkRoleStatus() async {
    final isStaff = await _authService.isStaff();
    final isAdmin = await _authService.isAdmin();
    setState(() {
      _isStaffOrAdmin = isStaff || isAdmin;
    });
  }

  // Create a new announcement (only for staff/admin)
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

  // Delete an announcement (only for staff/admin)
  Future<void> _deleteAnnouncement(String id) async {
    try {
      await _supabase.from('announcements').delete().eq('id', id);
      _fetchAnnouncements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting announcement: $e')),
      );
    }
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
          _isStaffOrAdmin
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
                    final String creatorName = "Faculty Member";

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
                                if (_isStaffOrAdmin)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete Announcement',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Announcement',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this announcement?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirm == true) {
                                        _deleteAnnouncement(
                                          announcement['id'].toString(),
                                        );
                                      }
                                    },
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
