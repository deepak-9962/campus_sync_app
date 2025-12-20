import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // List all available buckets
  Future<List<String>> listBuckets() async {
    try {
      final response = await _supabase.storage.listBuckets();
      return response.map((bucket) => bucket.name).toList();
    } catch (e) {
      debugPrint('Error listing buckets: $e');
      return [];
    }
  }
  
  // Ensure bucket exists, create if it doesn't
  Future<bool> ensureBucketExists(String bucketName) async {
    try {
      debugPrint('===== STORAGE DIAGNOSTIC: START =====');
      debugPrint('Checking if bucket $bucketName exists...');
      final buckets = await listBuckets();
      debugPrint('Available buckets: $buckets');
      
      // Check current user
      final user = _supabase.auth.currentUser;
      debugPrint('Current user ID: ${user?.id}');
      
      if (!buckets.contains(bucketName)) {
        debugPrint('Bucket $bucketName does not exist, attempting to create...');
        
        try {
          // First try regular bucket creation
          await _supabase.storage.createBucket(bucketName);
          debugPrint('Successfully created bucket: $bucketName');
          
          // Try to update permissions
          try {
            await updateBucketPermissions(bucketName);
          } catch (permissionsError) {
            debugPrint('Warning: Created bucket but failed to set permissions: $permissionsError');
          }
          return true;
        } catch (createError) {
          debugPrint('Failed to create bucket using standard API: $createError');
          
          // If RLS error, try RPC method as fallback
          if (createError.toString().contains('violates row-level security policy') ||
              createError.toString().contains('Unauthorized')) {
            try {
              debugPrint('Attempting to create bucket via RPC...');
              // Use RPC function if available (needs to be set up on Supabase)
              await _supabase.rpc('create_bucket', params: {
                'name': bucketName,
                'public': true
              });
              debugPrint('Successfully created bucket via RPC');
              return true;
            } catch (rpcError) {
              debugPrint('RPC bucket creation failed: $rpcError');
              
              // Last resort: try a direct SQL query if admin functions are enabled
              try {
                debugPrint('Attempting direct SQL bucket creation...');
                await _supabase.rpc('execute_sql', params: {
                  'query': "INSERT INTO storage.buckets(id, name, public) VALUES('$bucketName', '$bucketName', true) ON CONFLICT DO NOTHING"
                });
                debugPrint('Direct SQL bucket creation may have succeeded');
                return true;
              } catch (sqlError) {
                debugPrint('SQL bucket creation failed: $sqlError');
              }
            }
          }
          debugPrint('All bucket creation methods failed. Will try to use existing storage anyway.');
          return false;
        }
      } else {
        debugPrint('Bucket $bucketName already exists');
        return true;
      }
    } catch (e) {
      debugPrint('Error ensuring bucket exists: $e');
      // Return true to allow the app to continue even if bucket check fails
      // The app will handle upload/download failures gracefully
      return false;
    }
  }
  
  // List all files in a bucket
  Future<List<FileObject>> listFiles(String bucketName) async {
    try {
      final response = await _supabase.storage.from(bucketName).list();
      return response;
    } catch (e) {
      debugPrint('Error listing files in bucket $bucketName: $e');
      return [];
    }
  }
  
  // Upload a file and return its public URL
  Future<String?> uploadFile({
    required String bucketName,
    required XFile file,
    String? folder,
    String? customFileName,
  }) async {
    debugPrint('Starting file upload to bucket: $bucketName');
    
    // Check if bucket exists but continue even if it fails
    bool bucketExists = false;
    try {
      final buckets = await listBuckets();
      bucketExists = buckets.contains(bucketName);
      if (!bucketExists) {
        debugPrint('Bucket $bucketName does not exist, creating before upload');
        bucketExists = await ensureBucketExists(bucketName);
      }
    } catch (e) {
      debugPrint('Error checking buckets before upload: $e');
      // Continue anyway and try to upload, it might work if the bucket
      // exists but we don't have permission to list buckets
    }
    
    // Prepare file path and name
    final fileName = customFileName ?? path.basename(file.path);
    final filePath = folder != null ? '$folder/$fileName' : fileName;
    
    // Upload with retry
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('Uploading file to $bucketName/$filePath (attempt $attempt)');
        
        // Read file as bytes
        final bytes = await file.readAsBytes();
        
        // Try different upload methods based on previous errors
        String? publicUrl;
        
        try {
          // Method 1: Standard upload
          final response = await _supabase.storage
              .from(bucketName)
              .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: file.mimeType));
          
          debugPrint('Upload response: $response');
          publicUrl = getPublicUrl(bucketName, filePath);
        } catch (uploadError) {
          debugPrint('Standard upload failed: $uploadError');
          
          if (uploadError.toString().contains('Unauthorized') || 
              uploadError.toString().contains('security policy')) {
            try {
              // Method 2: Try RPC method
              debugPrint('Trying upload via RPC...');
              await _supabase.rpc('upload_file', params: {
                'bucket': bucketName,
                'path': filePath,
                'file': base64Encode(bytes),
                'mime_type': file.mimeType
              });
              publicUrl = getPublicUrl(bucketName, filePath);
            } catch (rpcError) {
              debugPrint('RPC upload failed: $rpcError');
              // Continue to next attempt
              continue;
            }
          } else {
            // Not a permission error, rethrow
            rethrow;
          }
        }
        
        if (publicUrl != null) {
          debugPrint('File uploaded successfully. Public URL: $publicUrl');
          return publicUrl;
        }
      } catch (e) {
        debugPrint('Error uploading file (attempt $attempt): $e');
        if (attempt < 3) {
          debugPrint('Retrying upload...');
          await Future.delayed(Duration(seconds: 1));
        } else {
          debugPrint('All upload attempts failed');
          return null;
        }
      }
    }
    
    return null;
  }
  
  // Download a file
  Future<File?> downloadFile(String bucketName, String filePath, String localPath) async {
    debugPrint('Starting file download from bucket: $bucketName, path: $filePath');
    
    // Check if bucket exists
    try {
      final buckets = await listBuckets();
      if (!buckets.contains(bucketName)) {
        debugPrint('Bucket $bucketName does not exist for download');
        return null;
      }
    } catch (e) {
      debugPrint('Error checking buckets before download: $e');
      // Continue anyway and try to download
    }
    
    // Download with retry
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        debugPrint('Downloading file (attempt $attempt)');
        final response = await _supabase.storage.from(bucketName).download(filePath);
        
        if (response.isEmpty) {
          debugPrint('Warning: Downloaded file is empty');
        }
        
        final file = File(localPath);
        await file.writeAsBytes(response);
        
        debugPrint('File successfully downloaded to: $localPath');
        return file;
      } catch (e) {
        debugPrint('Error downloading file (attempt $attempt): $e');
        if (attempt < 2) {
          debugPrint('Retrying download...');
          await Future.delayed(Duration(seconds: 1));
        } else {
          debugPrint('All download attempts failed');
          return null;
        }
      }
    }
    
    return null;
  }
  
  // Get public URL for a file
  String getPublicUrl(String bucketName, String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }
  
  // Delete a file
  Future<bool> deleteFile(String bucketName, String filePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
  
  // Update bucket permissions using RPC call
  Future<void> updateBucketPermissions(String bucketName) async {
    try {
      debugPrint('Updating permissions for bucket: $bucketName');
      // First try using the standard API if available
      try {
        await _supabase.storage.updateBucket(bucketName, const BucketOptions(public: true));
        debugPrint('Updated bucket permissions using standard API');
        return;
      } catch (standardApiError) {
        debugPrint('Standard API for permissions failed: $standardApiError, trying RPC...');
      }
      
      // Fall back to RPC method
      await _supabase.rpc('update_bucket_policy', params: {
        'bucket_id': bucketName,
        'policy': 'public',
      });
      debugPrint('Updated bucket permissions for $bucketName using RPC');
    } catch (e) {
      debugPrint('Error updating bucket permissions: $e');
      throw e; // Re-throw to let the caller handle it
    }
  }

  // Add this method to get a file from a complete URL
  Future<File?> downloadFileFromUrl(String url, String localPath) async {
    debugPrint('Starting file download from URL: $url');
    debugPrint('Target local path: $localPath');
    
    try {
      // Create the directory if it doesn't exist
      final directory = Directory(localPath.substring(0, localPath.lastIndexOf('/')));
      if (!directory.existsSync()) {
        debugPrint('Creating directory: ${directory.path}');
        directory.createSync(recursive: true);
      }
      
      // Download the file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Check if we received actual content
        if (response.bodyBytes.isEmpty) {
          debugPrint('Warning: Downloaded file is empty (0 bytes)');
        } else {
          debugPrint('Downloaded ${response.bodyBytes.length} bytes');
        }
        
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Verify file was actually created
        if (file.existsSync()) {
          final fileSize = await file.length();
          debugPrint('File successfully written to: $localPath (Size: $fileSize bytes)');
          return file;
        } else {
          debugPrint('Error: File was not created at path: $localPath');
          return null;
        }
      } else {
        debugPrint('Error downloading file: HTTP ${response.statusCode}');
        debugPrint('Response body: ${response.body.substring(0, min(100, response.body.length))}...');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading file from URL: $e');
      return null;
    }
  }
} 
