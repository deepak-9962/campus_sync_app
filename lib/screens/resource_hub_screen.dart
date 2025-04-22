import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../services/resource_service.dart';
import '../services/storage_service.dart';

final supabase = Supabase.instance.client;

class ResourceHubScreen extends StatefulWidget {
  final String department;
  final int semester;

  const ResourceHubScreen({
    Key? key,
    this.department = 'CSE',
    this.semester = 4,
  }) : super(key: key);

  @override
  _ResourceHubScreenState createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> {
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isGridView = true;
  
  // Resource lists
  final List<ResourceItemModel> _lectureNotes = [];
  final List<ResourceItemModel> _labManuals = [];
  final List<ResourceItemModel> _referenceBooks = [];
  
  // Storage service for interacting with Supabase
  late StorageService _storageService;
  late String _bucketName;
  
  // List of PDF resources with their public URLs
  final List<Map<String, String>> _pdfResources = [];
  
  @override
  void initState() {
    super.initState();
    _initResourceService();
    _loadResources();
    _pdfResources.clear(); // Clear PDF resources list
    _lectureNotes.addAll([
      ResourceItemModel(
        id: '1',
        title: 'Environmental Science',
        subject: 'CSE - Environmental Science',
        date: '2025-04-15',
        fileSize: '915 KB',
        fileType: 'PDF',
        fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/Computer%20Science%20Engineering/SEM4/lecture%20notes/Unit%20II%20-%20Environmental%20pollution.pdf',
        sampleContent: 'Introduction to environmental concepts and paradigms.',
      ),
      // Add more lecture notes here if needed
    ]);
  }
  
  Future<void> _initResourceService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Set the bucket name
      final bucketName = 'academic-resources';
      _bucketName = bucketName;
      
      // Initialize storage service
      _storageService = StorageService();
      
      // Load sample data
      await _loadResources();
      
      // Check buckets in Supabase (optional)
      await _checkBuckets();
      
    } catch (e) {
      print('Error initializing resource service: $e');
      _showSnackBar('Error loading resources: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load sample resources for display
  Future<void> _loadResources() async {
    try {
      // Removed 'Introduction to Programming' file from lecture notes
      // _lectureNotes.add(
      //   ResourceItemModel(
      //     id: '2',
      //     title: 'Introduction to Programming',
      //     subject: 'CSE - Programming Fundamentals',
      //     date: '2025-04-15',
      //     fileSize: '2.5 MB',
      //     fileType: 'PDF',
      //     fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/Computer%20Science%20Engineering/SEM4/lecture%20notes/Unit%20II%20-%20Environmental%20pollution.pdf',
      //     sampleContent: 'Introduction to programming concepts and paradigms.',
      //   )
      // );
      
      // Removed all lab manual files
      // _labManuals.add(
      //   ResourceItemModel(
      //     id: '3',
      //     title: 'Data Structures Lab',
      //     subject: 'CSE - Data Structures',
      //     date: '2025-04-10',
      //     fileSize: '3.2 MB',
      //     fileType: 'PDF',
      //     sampleContent: 'Lab manual for data structures and algorithms.',
      //   )
      // );
      
      // Removed all reference book files
      // _referenceBooks.add(
      //   ResourceItemModel(
      //     id: '4',
      //     title: 'Database Systems',
      //     subject: 'CSE - Database Management',
      //     date: '2025-03-25',
      //     fileSize: '8.7 MB',
      //     fileType: 'PDF',
      //     sampleContent: 'Comprehensive guide to database systems and SQL.',
      //   )
      // );
      
      print('Resources loaded successfully');
    } catch (e) {
      print('Error loading resources: $e');
    }
  }
  
  // Check available buckets in Supabase
  Future<void> _checkBuckets() async {
    try {
      final buckets = await _storageService.listBuckets();
      print('Available Supabase buckets: $buckets');
      
      if (buckets.isEmpty) {
        _showSnackBar('No storage buckets found in Supabase.');
      } else if (!buckets.contains(_bucketName)) {
        _showSnackBar('Warning: Bucket "$_bucketName" not found.');
      } else {
        _showSnackBar('Connected to bucket: $_bucketName');
      }
    } catch (e) {
      print('Error checking buckets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Hub'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3, // Three tabs
              child: Column(
                children: [
                  Container(
                    color: Colors.blue,
                    child: const TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      tabs: [
                        Tab(text: 'Lecture Notes'),
                        Tab(text: 'Lab Manuals'),
                        Tab(text: 'Reference Books'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildResourceList(_lectureNotes, 'Lecture Notes'),
                        _buildResourceList(_labManuals, 'Lab Manuals'),
                        _buildResourceList(_referenceBooks, 'Reference Books'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show add resource dialog
          _showSnackBar('Add resource functionality coming soon');
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Build a resource list for a specific category
  Widget _buildResourceList(List<ResourceItemModel> items, String category) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $category available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some resources to get started',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Use grid view or list view based on preference
    return _isGridView
        ? _buildResourceGrid(items)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildResourceListItem(items[index]);
            },
          );
  }

  // Build a grid view of resources
  Widget _buildResourceGrid(List<ResourceItemModel> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _navigateToContentPreview(items[index]),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with file type
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(items[index].fileType),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File type icon
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getFileTypeColor(items[index].fileType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getFileIcon(items[index].fileType),
                            color: _getFileTypeColor(items[index].fileType),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        items[index].title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Subject
                      Text(
                        items[index].subject,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Info row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            items[index].date,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            items[index].fileSize,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        label: Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                        onPressed: () => _downloadResource(items[index]),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build a list item for a resource
  Widget _buildResourceListItem(ResourceItemModel resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFileTypeColor(resource.fileType),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              _getFileIcon(resource.fileType),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Text(
          resource.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(resource.subject),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  resource.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  resource.fileSize,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () => _downloadResource(resource),
        ),
        onTap: () => _navigateToContentPreview(resource),
      ),
    );
  }

  // Navigate to content preview
  void _navigateToContentPreview(ResourceItemModel resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourcePreviewScreen(
          resource: resource,
          onDownload: () => _downloadResource(resource),
        ),
      ),
    );
  }

  // Handle resource download
  void _downloadResource(ResourceItemModel resource) {
    // For demonstration, just mark as downloaded
    setState(() {
      resource.isDownloaded = true;
    });
    
    // If there's a file URL, try to open it in the browser
    if (resource.fileUrl != null && resource.fileUrl!.isNotEmpty) {
      _launchPdfUrl(resource.fileUrl!);
    } else {
      _showSnackBar('${resource.title} downloaded successfully');
    }
  }

  // Launch PDF URL in browser
  Future<void> _launchPdfUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar('Error opening file: $e');
    }
  }

  // Show snackbar helper
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Get color based on file type
  Color _getFileTypeColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Colors.red.shade700;
      case 'DOC':
      case 'DOCX':
        return Colors.blue.shade700;
      case 'PPT':
      case 'PPTX':
        return Colors.orange.shade700;
      case 'XLS':
      case 'XLSX':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Get icon based on file type
  IconData _getFileIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// Simple resource item model class
class ResourceItemModel {
  final String id;
  final String title;
  final String subject;
  final String date;
  final String fileSize;
  final String fileType;
  final String? fileUrl;
  final String? localPath;
  final String? sampleContent;
  bool isDownloaded;
  bool isDownloading;

  ResourceItemModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.fileSize,
    required this.fileType,
    this.fileUrl,
    this.localPath,
    this.sampleContent,
    this.isDownloaded = false,
    this.isDownloading = false,
  });
}

// Resource preview screen
class ResourcePreviewScreen extends StatelessWidget {
  final ResourceItemModel resource;
  final Function() onDownload;

  const ResourcePreviewScreen({
    Key? key,
    required this.resource,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          resource.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[200],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resource.subject} • ${resource.fileSize}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.sampleContent ?? 'No content available',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (resource.fileUrl != null && resource.fileUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.link, size: 40, color: Colors.blue),
                            const SizedBox(height: 8),
                            const Text('This document can be viewed online.'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('OPEN IN BROWSER'),
                              onPressed: () async {
                                final Uri uri = Uri.parse(resource.fileUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open file')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD'),
                onPressed: onDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('SHARE'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share functionality coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}