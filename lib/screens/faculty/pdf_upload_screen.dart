import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import '../../services/pdf_resource_service.dart';

class PdfUploadScreen extends StatefulWidget {
  final String department;
  final int semester;
  
  const PdfUploadScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  _PdfUploadScreenState createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final PdfResourceService _pdfService = PdfResourceService();
  
  String _selectedCategory = 'Lecture Notes';
  XFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  
  final List<String> _categories = [
    'Lecture Notes',
    'Lab Manuals',
    'Reference Books',
    'Question Papers',
    'Assignments',
    'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _pdfService.initialize();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = XFile(result.files.first.path!);
          
          // Auto-fill title from filename
          final fileName = path.basenameWithoutExtension(result.files.first.path!);
          if (_titleController.text.isEmpty) {
            _titleController.text = fileName;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting PDF: $e')),
      );
    }
  }
  
  Future<void> _uploadPdf() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a PDF file to upload';
      });
      return;
    }
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
    
    try {
      final result = await _pdfService.uploadPdfResource(
        pdfFile: _selectedFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        department: widget.department,
        semester: widget.semester,
        category: _selectedCategory,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
      
      setState(() {
        _isUploading = false;
      });
      
      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reset form
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedFile = null;
            _uploadProgress = 0.0;
          });
          
          // Navigate back
          Navigator.pop(context, true);
        }
      } else {
        // Show error message
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to upload PDF';
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload PDF Resource'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Department and semester info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Department: ${widget.department}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Semester: ${widget.semester}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // File selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickPdfFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select PDF File'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Selected file info
                if (_selectedFile != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.basename(_selectedFile!.path),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                FutureBuilder<FileStat>(
                                  future: File(_selectedFile!.path).stat(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final fileSizeBytes = snapshot.data!.size;
                                      final fileSizeMB = fileSizeBytes / (1024 * 1024);
                                      return Text(
                                        'Size: ${fileSizeMB.toStringAsFixed(2)} MB',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Upload progress
                if (_isUploading)
                  Column(
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),
                
                // New Upload button with modern design
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isUploading ? null : _uploadPdf,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploading ? 'Uploading...' : 'Upload PDF Now',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Original Upload button (keeping for backward compatibility)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isUploading
                        ? const Text('Uploading...')
                        : const Text('Upload PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
