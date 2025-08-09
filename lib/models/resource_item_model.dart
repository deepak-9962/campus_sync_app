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
    );
  }
} 
