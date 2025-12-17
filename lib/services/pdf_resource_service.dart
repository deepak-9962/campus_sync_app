import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class PdfResourceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // Constants
  static const String bucketName = 'resource_files';
  static const String resourcesTable = 'resources';

  // Initialize the service
  Future<bool> initialize() async {
    debugPrint('Initializing PDF Resource Service');
    return await _storageService.ensureBucketExists(bucketName);
  }

  // Upload a PDF document and save its metadata
  Future<Map<String, dynamic>> uploadPdfResource({
    required XFile pdfFile,
    required String title,
    required String description,
    required String department,
    required int semester,
    required String category,
    Function(double)? onProgress,
  }) async {
    debugPrint('Uploading PDF resource: $title');

    try {
      // First, ensure the user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'resourceId': null,
        };
      }

      // Upload the PDF file using existing StorageService API
      final publicUrl = await _storageService.uploadFile(
        bucketName: bucketName,
        file: pdfFile,
        folder: '$department/SEM$semester/$category',
      );
      if (publicUrl == null) {
        return {
          'success': false,
          'error': 'Failed to upload PDF',
          'resourceId': null,
        };
      }
      // Derive file path from URL (Supabase public URL typically ends with bucket/path)
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      // Find index of bucket name and join the rest as file path
      final bucketIndex = pathSegments.indexOf(bucketName);
      final filePath =
          bucketIndex >= 0 && bucketIndex + 1 < pathSegments.length
              ? pathSegments.sublist(bucketIndex + 1).join('/')
              : '';
      // Best effort size (optional: could be added later by reading XFile length)
      final fileSize = await pdfFile.length();

      // Create resource metadata in the database
      final resourceData = {
        'title': title,
        'description': description,
        'department': department,
        'semester': semester,
        'category': category,
        'file_path': filePath,
        'file_url': publicUrl,
        'file_type': 'pdf',
        'file_size': fileSize,
        'uploaded_by': user.id,
      };

      // Insert into database
      final response =
          await _supabase
              .from(resourcesTable)
              .insert(resourceData)
              .select('id')
              .single();

      return {
        'success': true,
        'error': null,
        'resourceId': response['id'],
        'fileUrl': publicUrl,
      };
    } catch (e) {
      debugPrint('Error in uploadPdfResource: $e');
      return {'success': false, 'error': e.toString(), 'resourceId': null};
    }
  }

  // Get PDF resources by department, semester, and category
  Future<List<Map<String, dynamic>>> getPdfResources({
    required String department,
    required int semester,
    String? category,
  }) async {
    try {
      var query = _supabase
          .from(resourcesTable)
          .select('*')
          .eq('department', department)
          .eq('semester', semester)
          .eq('file_type', 'pdf');

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching PDF resources: $e');
      return [];
    }
  }

  // Download a PDF file and save it locally
  Future<String?> downloadPdf(String fileUrl, String fileName) async {
    try {
      // Get the downloads directory
      final downloadsDir = await getApplicationDocumentsDirectory();
      final localPath = '${downloadsDir.path}/pdfs/$fileName';

      // Download the file
      final file = await _storageService.downloadFileFromUrl(
        fileUrl,
        localPath,
      );

      if (file != null) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      return null;
    }
  }

  // Check if a PDF is already downloaded
  Future<String?> checkIfPdfExists(String fileName) async {
    try {
      final downloadsDir = await getApplicationDocumentsDirectory();
      final localPath = '${downloadsDir.path}/pdfs/$fileName';

      final file = File(localPath);
      if (file.existsSync()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error checking if PDF exists: $e');
      return null;
    }
  }

  // Delete a PDF resource
  Future<bool> deletePdfResource(String resourceId) async {
    try {
      // First get the resource to find the file path
      final resource =
          await _supabase
              .from(resourcesTable)
              .select('file_path')
              .eq('id', resourceId)
              .single();

      final filePath = resource['file_path'];

      // Delete from storage
      await _supabase.storage.from(bucketName).remove([filePath]);

      // Delete from database
      await _supabase.from(resourcesTable).delete().eq('id', resourceId);

      return true;
    } catch (e) {
      debugPrint('Error deleting PDF resource: $e');
      return false;
    }
  }
}
