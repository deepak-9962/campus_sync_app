import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/resource_service.dart' as resource_service;
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../services/storage_service.dart';
import '../models/resource_item_model.dart';
import '../services/supabase_setup.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/resource_item.dart' as widgets;
import 'preview_screen.dart';

// Create a lightweight resource item model for the screen
class ResourceItemModel {
  final String id;
  final String title;
  final String subject;
  final String date;
  final String fileSize;
  final String fileType;
  bool isDownloaded;
  bool isDownloading;
  String? sampleContent;
  String? fileUrl;
  String? localPath;
  
  ResourceItemModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.fileSize,
    required this.fileType,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.sampleContent,
    this.fileUrl,
    this.localPath,
  });
}

class ResourceHubScreen extends StatefulWidget {
  final String department;
  final int semester;

  const ResourceHubScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  @override
  _ResourceHubScreenState createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> {
  int _currentIndex = 0;
  List<ResourceItemModel> _lectureNotes = [];
  List<ResourceItemModel> _labManuals = [];
  List<ResourceItemModel> _referenceBooks = [];
  bool _isLoading = true;
  final resource_service.ResourceService _resourceService = resource_service.ResourceService();
  
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  String _selectedCategory = 'Lecture Notes';
  XFile? _selectedFile;
  String _selectedFileName = '';
  
  // Add view type state
  bool _isGridView = false;
  
  // Add StorageService
  late StorageService _storageService;
  late String _bucketName;
  
  @override
  void initState() {
    super.initState();
    _initResourceService();
  }
  
  Future<void> _initResourceService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Replace 'resources' with your actual bucket name from Supabase
      final bucketName = 'academic-resources';  // Changed to match your Supabase bucket
      
      // Check if we need to run setup
      final setup = SupabaseSetup();
      final setupSuccessful = await setup.initialize();
      
      if (!setupSuccessful) {
        debugPrint('Some Supabase setup steps failed, but continuing...');
      }
      
      _storageService = StorageService();
      _bucketName = bucketName;
      
      // Now try to load resources
      await _loadResources();
      
      // Add the specific resources from Supabase directly to the collection
      _addEnvironmentalPollutionResource();
      
      // Check buckets after a short delay to ensure UI is ready
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) _checkBuckets();
      });
    } catch (e) {
      debugPrint('Error in init: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing: ${e.toString().substring(0, min(50, e.toString().length))}...'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load resources
      debugPrint('Loading resources from Supabase...');
      final resourceService = resource_service.ResourceService();
      
      final lectureNotes = await resourceService.getResourcesByCategory('LECTURE_NOTES');
      final labManuals = await resourceService.getResourcesByCategory('LAB_MANUALS');
      final referenceBooks = await resourceService.getResourcesByCategory('REFERENCE_BOOKS');
      
      setState(() {
        _lectureNotes = lectureNotes.map(_convertToResourceItemModel).toList();
        _labManuals = labManuals.map(_convertToResourceItemModel).toList();
        _referenceBooks = referenceBooks.map(_convertToResourceItemModel).toList();
        
        // Remove any timetable resources that might have been added previously
        _lectureNotes.removeWhere((resource) => 
          resource.title == 'Semester 4 Timetable' || 
          (resource.fileUrl != null && resource.fileUrl!.contains('timetable/WhatsApp%20Image%202025-03-25')));
        
        _isLoading = false;
      });
      
      debugPrint('Resources loaded successfully.');
    } catch (e) {
      debugPrint('Error loading resources: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading resources: ${e.toString().substring(0, min(50, e.toString().length))}...'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Helper method to convert Resource to ResourceItemModel
  ResourceItemModel _convertToResourceItemModel(resource_service.Resource resource) {
    return ResourceItemModel(
      id: resource.id,
      title: resource.title,
      subject: resource.subject,
      date: resource.date,
      fileSize: resource.fileSize,
      fileType: resource.fileType,
      sampleContent: resource.previewText,
      fileUrl: resource.fileUrl,
      localPath: resource.localPath,
    );
  }
  
  void _loadSampleData() {
    _lectureNotes = [
      ResourceItemModel(
        id: '1',
        title: 'Introduction to Database',
        subject: 'Database Management Systems',
        date: '2023-09-15',
        fileSize: '2.5 MB',
        fileType: 'PDF',
        sampleContent: 'A database is an organized collection of structured information, or data, typically stored electronically in a computer system. A database is usually controlled by a database management system (DBMS). Together, the data and the DBMS, along with the applications that are associated with them, are referred to as a database system, often shortened to just database.\n\nData within the most common types of databases in operation today is typically modeled in rows and columns in a series of tables to make processing and data querying efficient. The data can then be easily accessed, managed, modified, updated, controlled, and organized. Most databases use structured query language (SQL) for writing and querying data.',
      ),
      ResourceItemModel(
        id: '2',
        title: 'SQL Basics',
        subject: 'Database Management Systems',
        date: '2023-09-22',
        fileSize: '1.8 MB',
        fileType: 'PDF',
        sampleContent: 'SQL (Structured Query Language) is a standard language for storing, manipulating and retrieving data in databases. Our SQL tutorial will teach you how to use SQL in: MySQL, SQL Server, MS Access, Oracle, Sybase, Informix, Postgres, and other database systems.\n\nSome common SQL commands:\n- SELECT - extracts data from a database\n- UPDATE - updates data in a database\n- DELETE - deletes data from a database\n- INSERT INTO - inserts new data into a database\n- CREATE DATABASE - creates a new database\n- ALTER DATABASE - modifies a database\n- CREATE TABLE - creates a new table\n- ALTER TABLE - modifies a table\n- DROP TABLE - deletes a table',
      ),
    ];
    
    _labManuals = [
      ResourceItemModel(
        id: '3',
        title: 'Lab 1: Database Setup',
        subject: 'DBMS Laboratory',
        date: '2023-09-18',
        fileSize: '3.2 MB',
        fileType: 'PDF',
        sampleContent: 'Lab 1: Setting Up Your Database Environment\n\nObjectives:\n- Install MySQL Database Server\n- Create a new database\n- Create tables and relationships\n- Insert sample data\n- Write basic queries\n\nStep 1: Download and install MySQL from https://dev.mysql.com/downloads/\nStep 2: Open MySQL Workbench and connect to your local server\nStep 3: Create a new database called "university"\nStep 4: Create tables for students, courses, and enrollments\nStep 5: Define primary and foreign keys\nStep 6: Insert sample data\nStep 7: Write SELECT queries to retrieve information',
      ),
    ];
    
    _referenceBooks = [
      ResourceItemModel(
        id: '4',
        title: 'Database System Concepts',
        subject: 'DBMS Reference',
        date: '2023-08-10',
        fileSize: '15.6 MB',
        fileType: 'PDF',
        sampleContent: 'Database System Concepts - 7th Edition\nBy Abraham Silberschatz, Henry F. Korth, S. Sudarshan\n\nChapter 1: Introduction\n\nA database-management system (DBMS) is a collection of interrelated data and a set of programs to access those data. The collection of data, usually referred to as the database, contains information relevant to an enterprise. The primary goal of a DBMS is to provide a way to store and retrieve database information that is both convenient and efficient.\n\nDatabase systems are designed to manage large bodies of information. Management of data involves both defining structures for storage of information and providing mechanisms for the manipulation of information. In addition, the database system must ensure the safety of the information stored, despite system crashes or attempts at unauthorized access.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resource Hub',
          style: TextStyle(
            fontFamily: 'Clash Grotesk', 
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        toolbarHeight: 40,
        elevation: 0,
        actions: [
          // Add view toggle button
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, size: 16),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 16),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: _loadResources,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1)
              ),
            ),
            child: Row(
              children: [
                _buildTabButton('LECTURE NOTES', 0),
                _buildTabButton('LAB MANUALS', 1),
                _buildTabButton('REFERENCE BOOKS', 2),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Enhanced header with shadow and better styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: Offset(0, 2)
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.department}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Clash Grotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Semester ${widget.semester}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[700],
                          fontFamily: 'Clash Grotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getCurrentCategory(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildCurrentView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceDialog,
        icon: Icon(Icons.add, size: 14),
        label: Text('ADD', style: TextStyle(fontSize: 10)),
        tooltip: 'Add Resource',
        extendedPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Clash Grotesk',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 8,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0:
        return _buildResourceList(_lectureNotes, 'lecture_notes');
      case 1:
        return _buildResourceList(_labManuals, 'lab_manuals');
      case 2:
        return _buildResourceList(_referenceBooks, 'reference_books');
      default:
        return Container();
    }
  }

  Widget _buildResourceList(List<ResourceItemModel> items, String categoryType) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 70,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No resources available',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Clash Grotesk',
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add resources',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Clash Grotesk',
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Return grid view if selected
    if (_isGridView) {
      return _buildResourceGrid(items);
    }

    // Clean resource list without any feature buttons
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(items[index].id),
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.file_download, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Download action
              _downloadResource(items[index]);
              return false; // Don't dismiss the item
            } else if (direction == DismissDirection.endToStart) {
              // Delete action
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete "${items[index].title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('DELETE', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                _showSnackBar('${items[index].title} deleted');
                // Remove from list 
                setState(() {
                  items.removeAt(index);
                });
                return true;
              }
              return false;
            }
            return false;
          },
          child: Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(items[index].fileType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    items[index].fileType,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              title: Text(
                items[index].title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Clash Grotesk',
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1),
                  Text(
                    items[index].subject,
                    style: TextStyle(
                      fontFamily: 'Clash Grotesk',
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 8,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          items[index].date,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          items[index].fileSize,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: SizedBox(
                width: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        items[index].isDownloaded ? Icons.check_circle : Icons.file_download_outlined,
                        size: 12,
                      ),
                      padding: EdgeInsets.all(0),
                      constraints: BoxConstraints(),
                      onPressed: () {
                        _downloadResource(items[index]);
                      },
                    ),
                    SizedBox(width: 1),
                    IconButton(
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 12,
                      ),
                      padding: EdgeInsets.all(0),
                      constraints: BoxConstraints(),
                      onPressed: () {
                        _navigateToContentPreview(items[index]);
                      },
                    ),
                  ],
                ),
              ),
              onTap: () {
                _navigateToContentPreview(items[index]);
              },
              onLongPress: () {
                _showQuickActionsMenu(context, items[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadButton(ResourceItemModel resource) {
    if (resource.isDownloaded) {
      return IconButton(
        icon: Icon(Icons.check_circle, color: Colors.green),
        onPressed: () {
          _showSnackBar('${resource.title} already downloaded');
        },
      );
    } else {
      return IconButton(
        icon: Icon(Icons.file_download_outlined),
        onPressed: () {
          _downloadResource(resource);
        },
      );
    }
  }

  Future<void> _downloadResource(ResourceItemModel resource) async {
    setState(() {
      resource.isDownloading = true;
    });
    
    try {
      if (resource.fileUrl == null || resource.fileUrl!.isEmpty) {
        _showSnackBar('No file URL available for ${resource.title}');
        setState(() {
          resource.isDownloading = false;
        });
        return;
      }
      
      _showSnackBar('Downloading ${resource.title}...');
      
      // Create a proper file name that's safe for storage
      final cleanTitle = resource.title.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanTitle.${resource.fileType.toLowerCase()}';
      final downloadsDir = Directory('${Directory.systemTemp.path}/campus_sync_downloads');
      
      // Create downloads directory if it doesn't exist
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      
      final localPath = '${downloadsDir.path}/$fileName';
      
      debugPrint('Downloading file to: $localPath');
      debugPrint('From URL: ${resource.fileUrl}');
      
      // Use the direct URL download method
      final file = await _storageService.downloadFileFromUrl(
        resource.fileUrl!,
        localPath
      );
      
      if (file != null) {
        _showSnackBar('${resource.title} downloaded successfully');
        
        setState(() {
          resource.isDownloading = false;
          resource.isDownloaded = true;
          resource.localPath = file.path;
        });
        
        debugPrint('File saved to: ${file.path}');
        
        // Open PDF files immediately after download
        if (resource.fileType.toUpperCase() == 'PDF') {
          _openPdfFile(resource);
        }
      } else {
        setState(() {
          resource.isDownloading = false;
        });
        _showSnackBar('Failed to download ${resource.title}');
      }
    } catch (e) {
      setState(() {
        resource.isDownloading = false;
      });
      
      final errorMsg = 'Error downloading file: ${e.toString().substring(0, min(e.toString().length, 100))}';
      _showSnackBar(errorMsg);
      debugPrint('Download error: $e');
    }
  }

  String _getCurrentCategory() {
    switch (_currentIndex) {
      case 0: return 'Lecture Notes';
      case 1: return 'Lab Manuals';
      case 2: return 'Reference Books';
      default: return 'Lecture Notes';
    }
  }

  // Updated method to handle both mobile and web PDF viewing
  void _navigateToContentPreview(ResourceItemModel resource) {
    // For PDFs, try to use direct web URL if available
    if (resource.fileType.toUpperCase() == 'PDF' && resource.fileUrl != null) {
      // For Supabase hosted files, we can open them directly in the browser or WebView
      if (resource.fileUrl!.contains('supabase.co/storage')) {
        _showPdfUrlOptions(resource);
        return;
      }
      
      // If we have a local path, try to open in PDF viewer
      if (resource.localPath != null) {
        _openPdfFile(resource);
        return;
      }
    }
    
    // For other file types or if PDF handling fails, show the preview screen
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
  
  // Show dialog with options for viewing PDF
  void _showPdfUrlOptions(ResourceItemModel resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open PDF'),
        content: Text('How would you like to open this PDF?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource).then((_) {
                if (resource.localPath != null) {
                  _openPdfFile(resource);
                }
              });
            },
            child: Text('DOWNLOAD AND OPEN'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Still use the regular preview screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResourcePreviewScreen(
                    resource: resource,
                    onDownload: () => _downloadResource(resource),
                  ),
                ),
              );
            },
            child: Text('VIEW DETAILS'),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog() {
    _titleController.clear();
    _subjectController.clear();
    _selectedCategory = 'Lecture Notes';
    _selectedFile = null;
    _selectedFileName = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Resource'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject/Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: [
                        'Lecture Notes',
                        'Lab Manuals',
                        'Reference Books',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(Icons.attach_file),
                      label: Text(_selectedFileName.isEmpty ? 'Select PDF File' : 'Change PDF File'),
                      onPressed: () async {
                        try {
                          // Define the type of files to pick
                          final typeGroup = XTypeGroup(
                            label: 'PDFs',
                            extensions: ['pdf'],
                          );
                          
                          // Open file picker
                          final file = await openFile(
                            acceptedTypeGroups: [typeGroup],
                          );
                          
                          if (file != null) {
                            setState(() {
                              _selectedFile = file;
                              _selectedFileName = file.name;
                            });
                          }
                        } catch (e) {
                          _showSnackBar('Error selecting file: $e');
                        }
                      },
                    ),
                    if (_selectedFileName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Selected: $_selectedFileName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _subjectController.text.isEmpty) {
                      _showSnackBar('Please fill all fields');
                      return;
                    }
                    
                    // Add the new resource
                    _addResource(
                      _titleController.text,
                      _subjectController.text,
                      _selectedCategory,
                    );
                    
                    Navigator.pop(context);
                  },
                  child: Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _addResource(String title, String subject, String category) async {
    setState(() {
      _isLoading = true;
    });
    
    // Run setup to ensure user is admin
    try {
      await _resourceService.ensureSetupComplete();
    } catch (e) {
      print('Setup error: $e');
    }
    
    // Check if we can access storage
    bool hasStorage = false;
    try {
      final buckets = await _storageService.listBuckets();
      hasStorage = buckets.contains(_bucketName);
      if (!hasStorage) {
        // Try to create it one more time
        hasStorage = await _storageService.ensureBucketExists(_bucketName);
      }
    } catch (e) {
      print('Storage check failed: $e');
      // Continue with hasStorage = false
    }
    
    // Show uploading indicator
    if (_selectedFile != null && hasStorage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Uploading file...'),
            ],
          ),
          duration: Duration(seconds: 30), // Long duration as uploads can take time
        ),
      );
      
      try {
        // First upload the file to storage bucket
        final fileUrl = await _storageService.uploadFile(
          bucketName: _bucketName, 
          file: _selectedFile!,
          folder: category.toLowerCase().replaceAll(' ', '_')
        );
        
        if (fileUrl != null) {
          // Create the resource with the file URL
          final resource = await _resourceService.addResource(
            title: title,
            subject: subject,
            department: widget.department,
            semester: widget.semester,
            category: category,
            fileType: _getFileTypeFromName(_selectedFile!.name),
            file: _selectedFile, // Pass the file directly
            previewText: 'This is a newly added resource created on ${DateTime.now().toString().substring(0, 10)}.\n\n$subject\n\nThe full content will be available after downloading the file.',
          );
          
          // Dismiss any existing snackbars
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (resource != null) {
            final newItem = _convertToResourceItemModel(resource);
            
            setState(() {
              switch (category) {
                case 'Lecture Notes':
                  _lectureNotes.add(newItem);
                  _currentIndex = 0;
                  break;
                case 'Lab Manuals':
                  _labManuals.add(newItem);
                  _currentIndex = 1;
                  break;
                case 'Reference Books':
                  _referenceBooks.add(newItem);
                  _currentIndex = 2;
                  break;
              }
            });
            
            _showSnackBar('Added: $title');
          } else {
            _showSnackBar('Failed to add resource to database. The resource will be displayed temporarily.');
            
            // Create a temporary resource for display
            _addTemporaryResource(title, subject, category);
          }
        } else {
          _showSnackBar('Failed to upload file');
          
          // Create a temporary resource even if upload failed
          _addTemporaryResource(title, subject, category);
        }
      } catch (e) {
        // Dismiss any existing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        String errorMessage = e.toString();
        // Simplify the error message for display
        if (errorMessage.length > 100) {
          errorMessage = '${errorMessage.substring(0, 100)}...';
        }
        
        _showSnackBar('Error: $errorMessage');
        print('Detailed error: $e');
        
        // Create a temporary resource even if upload failed
        _addTemporaryResource(title, subject, category);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // No file selected or storage not available, create resource without file
      if (_selectedFile != null && !hasStorage) {
        _showSnackBar('Storage is not available. Creating resource without file upload.');
      }
      
      try {
        final resource = await _resourceService.addResource(
          title: title,
          subject: subject,
          department: widget.department,
          semester: widget.semester,
          category: category,
          fileType: _selectedFile != null ? _getFileTypeFromName(_selectedFile!.name) : 'PDF',
          previewText: 'This is a newly added resource created on ${DateTime.now().toString().substring(0, 10)}.\n\n$subject',
        );
        
        if (resource != null) {
          final newItem = _convertToResourceItemModel(resource);
          
          setState(() {
            switch (category) {
              case 'Lecture Notes':
                _lectureNotes.add(newItem);
                _currentIndex = 0;
                break;
              case 'Lab Manuals':
                _labManuals.add(newItem);
                _currentIndex = 1;
                break;
              case 'Reference Books':
                _referenceBooks.add(newItem);
                _currentIndex = 2;
                break;
            }
          });
          
          _showSnackBar('Added: $title');
        } else {
          _showSnackBar('Failed to add resource to database');
          
          // Create a temporary resource for display
          _addTemporaryResource(title, subject, category);
        }
      } catch (e) {
        String errorMessage = e.toString();
        if (errorMessage.length > 100) {
          errorMessage = '${errorMessage.substring(0, 100)}...';
        }
        
        _showSnackBar('Error: $errorMessage');
        print('Detailed error: $e');
        
        // Create a temporary resource for display anyway
        _addTemporaryResource(title, subject, category);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper method to create a temporary resource when database operations fail
  void _addTemporaryResource(String title, String subject, String category) {
    final tempResource = ResourceItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subject: subject,
      date: DateTime.now().toString().substring(0, 10),
      fileSize: _selectedFile != null ? '1.0 MB' : '0.1 MB',
      fileType: _selectedFile != null ? _getFileTypeFromName(_selectedFile!.name) : 'PDF',
      sampleContent: 'This is a temporary resource created on ${DateTime.now().toString().substring(0, 10)}.\n\n$subject\n\nNote: This resource may not have been saved permanently due to a database error.',
    );
    
    setState(() {
      switch (category) {
        case 'Lecture Notes':
          _lectureNotes.add(tempResource);
          _currentIndex = 0;
          break;
        case 'Lab Manuals':
          _labManuals.add(tempResource);
          _currentIndex = 1;
          break;
        case 'Reference Books':
          _referenceBooks.add(tempResource);
          _currentIndex = 2;
          break;
      }
    });
  }
  
  // Helper method to get file type from file name
  String _getFileTypeFromName(String fileName) {
    final extension = fileName.split('.').last.toUpperCase();
    switch (extension) {
      case 'PDF':
        return 'PDF';
      case 'DOC':
      case 'DOCX':
        return 'DOC';
      case 'PPT':
      case 'PPTX':
        return 'PPT';
      case 'XLS':
      case 'XLSX':
        return 'XLS';
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return 'IMG';
      default:
        return extension.substring(0, min(3, extension.length));
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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

  // Check if user can add resources
  Future<bool> _canAddResources() async {
    try {
      // First check if user is admin
      bool isAdmin = await _resourceService.isAdmin();
      print('User is admin: $isAdmin');
      
      // Check storage access
      bool hasStorage = false;
      try {
        final buckets = await _storageService.listBuckets();
        hasStorage = buckets.contains(_bucketName);
        if (!hasStorage) {
          // Try to create it
          hasStorage = await _storageService.ensureBucketExists(_bucketName);
        }
        print('Has storage access: $hasStorage');
      } catch (e) {
        print('Storage check failed: $e');
      }
      
      return isAdmin;
    } catch (e) {
      print('Error checking if user can add resources: $e');
      return false;
    }
  }

  // Add this method to the _ResourceHubScreenState class
  Future<void> _checkBuckets() async {
    try {
      final buckets = await _storageService.listBuckets();
      print('Available Supabase buckets: $buckets');
      
      if (buckets.isEmpty) {
        _showSnackBar('No storage buckets found in Supabase. Please check your configuration.');
      } else if (!buckets.contains(_bucketName)) {
        _showSnackBar('Warning: Bucket "$_bucketName" not found. Available buckets: ${buckets.join(", ")}');
      } else {
        _showSnackBar('Successfully connected to bucket: $_bucketName');
        
        // Remove any timetable resources from collections
        _removeAllTimetableResources();
      }
    } catch (e) {
      print('Error checking buckets: $e');
      _showSnackBar('Error checking Supabase buckets: ${e.toString().substring(0, min(100, e.toString().length))}');
    }
  }

  // Add method to clean up all timetable resources
  void _removeAllTimetableResources() {
    int removedCount = 0;
    
    // Check for timetable resources in lecture notes
    removedCount += _lectureNotes.where((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable'))).length;
    
    _lectureNotes.removeWhere((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable')));
    
    // Check in lab manuals
    removedCount += _labManuals.where((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable'))).length;
      
    _labManuals.removeWhere((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable')));
    
    // Check in reference books
    removedCount += _referenceBooks.where((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable'))).length;
      
    _referenceBooks.removeWhere((resource) => 
      resource.title == 'Semester 4 Timetable' || 
      (resource.fileUrl != null && resource.fileUrl!.contains('timetable')));
    
    // Only show a message if resources were actually removed
    if (removedCount > 0) {
      setState(() {});  // Refresh the UI
      debugPrint('Removed $removedCount timetable resources from collections');
    }
  }

  // Add this method to access a specific file by URL
  void _accessSpecificResource() {
    // Create a resource model for the specific file
    final specificResource = ResourceItemModel(
      id: 'specific-resource',
      title: 'Environmental Pollution',
      subject: 'CSE - Semester 4 - Lecture Notes',
      date: DateTime.now().toString().substring(0, 10),
      fileSize: '2.5 MB', // Estimated size
      fileType: 'PDF',
      fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/CSE/SEM4/lecture%20notes/Unit%20II%20-%20Environmental%20pollution.pdf',
      sampleContent: 'This is the lecture notes on Environmental Pollution. Click download to access the full content.',
    );
    
    // Show a dialog to ask if user wants to view or add to collection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Environmental Pollution PDF'),
        content: Text('This resource is available in your Supabase bucket. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addSpecificResourceToCollection();
            },
            child: Text('ADD TO COLLECTION'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to preview screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResourcePreviewScreen(
                    resource: specificResource,
                    onDownload: () => _downloadSpecificResource(specificResource),
                  ),
                ),
              );
            },
            child: Text('VIEW RESOURCE'),
          ),
        ],
      ),
    );
  }
  
  // Download the specific resource
  Future<void> _downloadSpecificResource(ResourceItemModel resource) async {
    setState(() {
      resource.isDownloading = true;
    });
    
    try {
      _showSnackBar('Downloading ${resource.title}...');
      
      // For direct URL download, we use the URL directly
      final fileName = 'Environmental_Pollution.pdf';
      final localPath = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Use the direct URL download method
      final file = await _storageService.downloadFileFromUrl(
        resource.fileUrl!,
        localPath
      );
      
      setState(() {
        resource.isDownloading = false;
        resource.isDownloaded = file != null;
      });
      
      if (file != null) {
        _showSnackBar('${resource.title} downloaded successfully');
        // Here you would typically open the file with a PDF viewer
      } else {
        _showSnackBar('Failed to download ${resource.title}');
      }
    } catch (e) {
      setState(() {
        resource.isDownloading = false;
      });
      
      final errorMsg = 'Error downloading file: ${e.toString().substring(0, min(e.toString().length, 100))}';
      _showSnackBar(errorMsg);
      print('Download error: $e');
    }
  }

  // Add the specific resource to lecture notes
  void _addSpecificResourceToCollection() {
    final specificResource = ResourceItemModel(
      id: 'specific-resource-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Environmental Pollution',
      subject: 'CSE - Semester 4 - Lecture Notes',
      date: DateTime.now().toString().substring(0, 10),
      fileSize: '2.5 MB', // Estimated size
      fileType: 'PDF',
      fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/CSE/SEM4/lecture%20notes/Unit%20II%20-%20Environmental%20pollution.pdf',
      sampleContent: 'This is the lecture notes on Environmental Pollution. Click download to access the full content.',
    );
    
    // Add to lecture notes collection
    setState(() {
      _lectureNotes.add(specificResource);
      _currentIndex = 0; // Switch to lecture notes tab
    });
    
    _showSnackBar('Environmental Pollution added to Lecture Notes');
  }

  // Add this method to add the specific resource from Supabase directly to the collection
  void _addEnvironmentalPollutionResource() {
    // Remove old version if it exists to replace with new one
    _lectureNotes.removeWhere((resource) => 
        resource.title == 'Environmental Pollution' && 
        (resource.fileUrl?.contains('Environmental%20pollution.pdf') == true ||
         resource.fileUrl?.contains('Unit%20II%20-%20Environmental%20pollution.pdf') == true));
    
    final specificResource = ResourceItemModel(
      id: 'specific-resource-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Environmental Pollution',
      subject: 'CSE - Semester 4 - Lecture Notes (ESS)',
      date: DateTime.now().toString().substring(0, 10),
      fileSize: '2.8 MB', // Updated size estimate
      fileType: 'PDF',
      fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/Computer%20Science%20Engineering/SEM4/lecture%20notes/Unit%20II%20-%20Environmental%20pollution.pdf',
      sampleContent: 'This document contains lecture notes on Environmental Pollution for Environmental Science and Sustainability course.\n\n'
          'Topics covered include:\n'
          '• Air pollution and its sources\n'
          '• Water pollution and control measures\n'
          '• Soil contamination\n'
          '• Noise pollution\n'
          '• Environmental protection strategies\n\n'
          'Click download to access the full content.',
    );
    
    // Add to lecture notes collection
    setState(() {
      // Add at the beginning of the list for high visibility
      _lectureNotes.insert(0, specificResource);
      _currentIndex = 0; // Switch to lecture notes tab
    });
    
    // No snackbar notification when adding automatically during initialization
  }

  // Add this method to add the timetable resource
  void _addTimetableResource() {
    // Method disabled - timetable resource removed as requested
    return;
    
    /* Original implementation commented out
    // Check if the resource already exists to avoid duplicates
    if (_lectureNotes.any((resource) => resource.title == 'Semester 4 Timetable' && 
        resource.fileUrl?.contains('WhatsApp%20Image%202025-03-25') == true)) {
      return; // Resource already exists in collection
    }
    
    final timetableResource = ResourceItemModel(
      id: 'timetable-resource-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Semester 4 Timetable',
      subject: 'CSE - Semester 4 - Timetable',
      date: DateTime.now().toString().substring(0, 10),
      fileSize: '1.5 MB', // Estimated size
      fileType: 'IMG',
      fileUrl: 'https://hgzhfqvjsyszwtdeaifx.supabase.co/storage/v1/object/public/academic-resources/CSE/SEM4/timetable/WhatsApp%20Image%202025-03-25%20at%2014.45.45_f5d83a29.jpg',
      sampleContent: 'This is the official timetable for Semester 4 Computer Science Engineering.\n\n'
          'The timetable includes:\n'
          '• Regular class schedules\n'
          '• Lab sessions\n'
          '• Tutorial timings\n'
          '• Important dates and deadlines\n\n'
          'Click download to view the full timetable.',
    );
    
    // Add to lecture notes collection
    setState(() {
      // Add at the beginning of the list for high visibility
      _lectureNotes.insert(0, timetableResource);
      _currentIndex = 0; // Switch to lecture notes tab
    });
    */
  }

  // Helper method to get file icon based on type
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
  
  // Show quick actions menu
  void _showQuickActionsMenu(BuildContext context, ResourceItemModel resource) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(resource.fileType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      resource.fileType,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  resource.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                subtitle: Text(resource.subject),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.visibility_outlined),
                title: Text('Preview'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToContentPreview(resource);
                },
              ),
              ListTile(
                leading: Icon(resource.isDownloaded ? Icons.check_circle : Icons.file_download_outlined),
                title: Text(resource.isDownloaded ? 'Downloaded' : 'Download'),
                onTap: () {
                  Navigator.pop(context);
                  if (!resource.isDownloaded) {
                    _downloadResource(resource);
                  } else {
                    _showSnackBar('${resource.title} already downloaded');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.file_upload_outlined),
                title: Text('Replace PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _showReplacePdfDialog(resource);
                },
              ),
              ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Share functionality not available in this version');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete "${resource.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('DELETE', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    _showSnackBar('${resource.title} deleted');
                    // Remove from appropriate list
                    setState(() {
                      switch (_currentIndex) {
                        case 0:
                          _lectureNotes.removeWhere((item) => item.id == resource.id);
                          break;
                        case 1:
                          _labManuals.removeWhere((item) => item.id == resource.id);
                          break;
                        case 2:
                          _referenceBooks.removeWhere((item) => item.id == resource.id);
                          break;
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Show dialog to replace a PDF with an older version
  void _showReplacePdfDialog(ResourceItemModel resource) {
    XFile? newFile;
    String selectedFileName = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Replace PDF'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current PDF: ${resource.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Clash Grotesk',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select an older version to replace the current PDF. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(Icons.upload_file),
                      label: Text('Select Replacement PDF'),
                      onPressed: () async {
                        try {
                          final imagePicker = ImagePicker();
                          final pickedFile = await imagePicker.pickMedia();
                          
                          if (pickedFile != null) {
                            setState(() {
                              newFile = pickedFile;
                              selectedFileName = pickedFile.name;
                            });
                          }
                        } catch (e) {
                          _showSnackBar('Error selecting file: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (selectedFileName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFileName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: newFile == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _replacePdf(resource, newFile!);
                        },
                  child: Text('REPLACE'),
                  style: TextButton.styleFrom(
                    foregroundColor: newFile == null ? Colors.grey : Colors.blue,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Replace PDF with an older version
  Future<void> _replacePdf(ResourceItemModel resource, XFile file) async {
    if (file.name.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _isLoading = true;
      });
      
      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Replacing PDF...'),
            ],
          ),
          duration: Duration(seconds: 30), // Long duration as uploads can take time
        ),
      );
      
      try {
        // Replace the resource with new file
        final updatedResource = await _resourceService.replaceResource(resource.id, file);
        
        // Dismiss any existing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (updatedResource != null) {
          final updatedItem = _convertToResourceItemModel(updatedResource);
          
          // Update the resource in the appropriate list
          setState(() {
            switch (_currentIndex) {
              case 0:
                final index = _lectureNotes.indexWhere((item) => item.id == resource.id);
                if (index >= 0) _lectureNotes[index] = updatedItem;
                break;
              case 1:
                final index = _labManuals.indexWhere((item) => item.id == resource.id);
                if (index >= 0) _labManuals[index] = updatedItem;
                break;
              case 2:
                final index = _referenceBooks.indexWhere((item) => item.id == resource.id);
                if (index >= 0) _referenceBooks[index] = updatedItem;
                break;
            }
          });
          
          _showSnackBar('PDF replaced successfully');
        } else {
          _showSnackBar('Failed to replace PDF');
        }
      } catch (e) {
        // Dismiss any existing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        String errorMessage = e.toString();
        // Simplify the error message for display
        if (errorMessage.length > 100) {
          errorMessage = '${errorMessage.substring(0, 100)}...';
        }
        
        _showSnackBar('Error: $errorMessage');
        print('Detailed error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showSnackBar('Please select a PDF file');
    }
  }

  // Method to check if file exists first, then open PDF viewer
  void _openPdfFile(ResourceItemModel resource) {
    debugPrint('Attempting to open PDF: ${resource.localPath}');
    
    if (resource.localPath == null) {
      _showSnackBar('PDF file not downloaded yet. Downloading now...');
      _downloadResource(resource).then((_) {
        if (resource.localPath != null) {
          _navigateToPdfViewer(resource);
        }
      });
      return;
    }

    File file = File(resource.localPath!);
    
    if (!file.existsSync()) {
      debugPrint('File does not exist at path: ${resource.localPath}');
      _showSnackBar('PDF file not found. Downloading again...');
      _downloadResource(resource).then((_) {
        if (resource.localPath != null) {
          _navigateToPdfViewer(resource);
        }
      });
      return;
    }
    
    debugPrint('PDF file found, opening viewer: ${file.path}');
    _navigateToPdfViewer(resource);
  }
  
  // Navigate to PDF viewer
  void _navigateToPdfViewer(ResourceItemModel resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          filePath: resource.localPath,
          resource: resource,
        ),
      ),
    );
  }

  // Clean resource list without any feature buttons
  Widget _buildResourceGrid(List<ResourceItemModel> items) {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
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
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(items[index].fileType),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File type icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getFileTypeColor(items[index].fileType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            _getFileIcon(items[index].fileType),
                            color: _getFileTypeColor(items[index].fileType),
                            size: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Title
                      Text(
                        items[index].title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Clash Grotesk',
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      // Subject
                      Text(
                        items[index].subject,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Info row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              items[index].date,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 10,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 2),
                          Text(
                            items[index].fileSize,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          items[index].isDownloaded
                              ? Icons.check_circle
                              : Icons.file_download_outlined,
                          size: 16,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(),
                        onPressed: () => _downloadResource(items[index]),
                        tooltip: items[index].isDownloaded ? 'Downloaded' : 'Download',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(),
                        onPressed: () => _navigateToContentPreview(items[index]),
                        tooltip: 'Preview',
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
}

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
          style: TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share functionality not available in this version')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            color: Colors.grey[200],
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${resource.subject} • ${resource.fileSize}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 10,
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
            child: resource.isDownloaded
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.sampleContent ?? 'No content available',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        if (resource.fileUrl != null && resource.fileUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.link, size: 40, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text('This document can be viewed online.'),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.open_in_new),
                                    label: Text('OPEN IN BROWSER'),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Open in browser not implemented in this version')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Content not available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please download this resource first',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: Icon(Icons.file_download),
                          label: Text('DOWNLOAD NOW'),
                          onPressed: onDownload,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: Icon(Icons.zoom_out, size: 12),
                label: Text('Zoom Out', style: TextStyle(fontSize: 9)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size(0, 0),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Zoom functionality not available in this version')),
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.zoom_in, size: 12),
                label: Text('Zoom In', style: TextStyle(fontSize: 9)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size(0, 0),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Zoom functionality not available in this version')),
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