class Resource {
  final String id;
  final String title;
  final String subject;
  final String department;
  final int semester;
  final String date;
  final String fileSize;
  final String fileType;
  final String category;
  final String? fileUrl;
  final String? filePath;
  final String? previewText;
  String? localPath; // Local path for downloaded files

  Resource({
    required this.id,
    required this.title,
    required this.subject,
    required this.department,
    required this.semester,
    required this.date,
    required this.fileSize,
    required this.fileType,
    required this.category,
    this.fileUrl,
    this.filePath,
    this.previewText,
    this.localPath,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['description'] ?? '',
      department: json['department'] ?? '',
      semester: json['semester'] ?? 0,
      date: json['created_at']?.toString().substring(0, 10) ?? DateTime.now().toString().substring(0, 10),
      fileSize: formatFileSize(json['file_size'] ?? 0),
      fileType: json['file_type']?.toUpperCase() ?? 'PDF',
      category: json['category'] ?? '',
      fileUrl: json['file_url'],
      filePath: json['file_path'],
      previewText: json['preview_text'],
      localPath: json['local_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': subject,
      'department': department,
      'semester': semester,
      'file_size': int.tryParse(fileSize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      'file_type': fileType.toLowerCase(),
      'category': category,
      'file_url': fileUrl,
      'file_path': filePath,
      'preview_text': previewText,
      'local_path': localPath,
    };
  }

  static String formatFileSize(dynamic size) {
    if (size is String) {
      try {
        size = int.parse(size);
      } catch (e) {
        return size;
      }
    }
    
    if (size == null || size == 0) {
      return '0 B';
    }
    
    int bytes = size is int ? size : 0;
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double dblBytes = bytes.toDouble();
    
    while (dblBytes >= 1024 && i < suffixes.length - 1) {
      dblBytes /= 1024;
      i++;
    }
    
    return '${dblBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }
} 
