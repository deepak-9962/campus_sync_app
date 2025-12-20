import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define a model for Lost and Found items
class LostFoundItem {
  final String id;
  final String userId;
  final String type; // 'lost' or 'found'
  final String description;
  final DateTime createdAt;
  final String? userName; // To display who posted

  LostFoundItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.createdAt,
    this.userName,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    // Removed userName parameter
    return LostFoundItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: null, // userName will not be fetched from DB
    );
  }
}

class LostAndFoundScreen extends StatefulWidget {
  const LostAndFoundScreen({super.key});

  @override
  State<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _LostAndFoundScreenState extends State<LostAndFoundScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<LostFoundItem> _items = [];
  bool _isLoading = true;
  String _error = '';

  // Light Theme Colors (consistent with HomeScreen)
  static const Color primaryLightBackground = Color(0xFFF5F5F5);
  static const Color cardLightBackground = Colors.white;
  static const Color primaryTextLight = Color(0xFF212121);
  static const Color secondaryTextLight = Color(0xFF757575);
  static const Color accentColorLight = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _supabase
          .from('lost_and_found_items')
          .select('id, user_id, type, description, created_at, contact_info, image_url')
          .order('created_at', ascending: false)
          .limit(100);

      // No .execute() needed here, the await handles it.
      // Error handling is done via try-catch for PostgrestErrors or other exceptions.

      final data =
          response as List<dynamic>; // response is directly the data or throws
      final List<LostFoundItem> fetchedItems = [];
      for (var itemData in data) {
        // No profile data to process here
        fetchedItems.add(
          LostFoundItem.fromJson(itemData as Map<String, dynamic>),
        );
      }
      setState(() {
        _items = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch items: ${e.toString()}';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error)));
      }
    }
  }

  Future<void> _addItem(String type, String description) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post.')),
      );
      return;
    }

    try {
      final response = await _supabase.from('lost_and_found_items').insert({
        'user_id': userId,
        'type': type,
        'description': description,
      });
      // No .execute() needed here for insert. It will throw an error if it fails.
      _fetchItems(); // Refresh the list
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.capitalize()} item posted successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post item: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final descriptionController = TextEditingController();
    String selectedType = 'lost'; // Default type

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // To update dialog state for radio buttons
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardLightBackground,
              title: const Text(
                'Post an Item',
                style: TextStyle(color: primaryTextLight),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'lost',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                          activeColor: accentColorLight,
                        ),
                        const Text(
                          'Lost',
                          style: TextStyle(color: primaryTextLight),
                        ),
                        Radio<String>(
                          value: 'found',
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                          activeColor: accentColorLight,
                        ),
                        const Text(
                          'Found',
                          style: TextStyle(color: primaryTextLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText:
                            'Describe who you are and about the lost or found thing', // Updated hint text
                        hintStyle: TextStyle(color: secondaryTextLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accentColorLight.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: accentColorLight.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: accentColorLight,
                            width: 2.0,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      style: const TextStyle(color: primaryTextLight),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: accentColorLight),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColorLight,
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (descriptionController.text.isNotEmpty) {
                      _addItem(selectedType, descriptionController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Description cannot be empty.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLightBackground,
      appBar: AppBar(
        title: const Text(
          'Lost and Found',
          style: TextStyle(color: primaryTextLight),
        ),
        backgroundColor: cardLightBackground,
        iconTheme: const IconThemeData(color: primaryTextLight),
        elevation: 0.5,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: accentColorLight),
              )
              : _error.isNotEmpty && _items.isEmpty
              ? Center(
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : _items.isEmpty
              ? Center(
                child: Text(
                  'No lost or found items yet.\nBe the first to post!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextLight, fontSize: 16),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchItems,
                color: accentColorLight,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      color: cardLightBackground,
                      elevation: 1.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 8.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          item.type == 'lost'
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                          color:
                              item.type == 'lost'
                                  ? Colors.orangeAccent
                                  : Colors.green,
                          size: 30,
                        ),
                        title: Text(
                          item.description,
                          style: const TextStyle(
                            color: primaryTextLight,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${item.type.capitalize()}',
                              style: TextStyle(
                                color: secondaryTextLight,
                                fontSize: 12,
                              ),
                            ),
                            // Removed: if (item.userName != null) Text('Posted by: ${item.userName}', ...)
                            Text(
                              'On: ${item.createdAt.toLocal().toString().substring(0, 16)}', // Format date
                              style: TextStyle(
                                color: secondaryTextLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine:
                            item.userName !=
                            null, // Adjust based on whether username would have been shown
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: accentColorLight,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
