import 'package:flutter/material.dart';

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
  String? department;
  int? semester;
  String? category;
  String? uploadedBy;

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
    this.department,
    this.semester,
    this.category,
    this.uploadedBy,
  });

  // Create a copy of the resource with updated properties
  ResourceItemModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? date,
    String? fileSize,
    String? fileType,
    bool? isDownloaded,
    bool? isDownloading,
    String? sampleContent,
    String? fileUrl,
    String? localPath,
    String? department,
    int? semester,
    String? category,
    String? uploadedBy,
  }) {
    return ResourceItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      sampleContent: sampleContent ?? this.sampleContent,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      category: category ?? this.category,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  // Create from Supabase response
  factory ResourceItemModel.fromSupabase(Map<String, dynamic> data) {
    return ResourceItemModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      subject: data['description'] ?? '',
      date: data['created_at']?.toString().substring(0, 10) ??
          DateTime.now().toString().substring(0, 10),
      fileSize: _formatFileSize(data['file_size'] ?? 0),
      fileType: data['file_type']?.toUpperCase() ?? 'PDF',
      fileUrl: data['file_url'],
      department: data['department'],
      semester: data['semester'],
      category: data['category'],
      uploadedBy: data['uploaded_by'],
      sampleContent: data['preview_text'],
    );
  }

  // Format file size helper
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if this is a PDF
  bool get isPdf => fileType.toUpperCase() == 'PDF';

  // Get file name from URL
  String? get fileName {
    if (fileUrl == null) return null;
    return fileUrl!.split('/').last;
  }
}
