import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../models/resource_item_model.dart';
import '../services/pdf_resource_service.dart';
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String? filePath;
  final ResourceItemModel resource;

  const PDFViewerScreen({
    Key? key,
    required this.filePath,
    required this.resource,
  }) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final PdfResourceService _pdfService = PdfResourceService();
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    // If we already have a local file path, verify it
    if (widget.filePath != null) {
      _verifyLocalFile(widget.filePath!);
      return;
    }

    // If we have a file URL but no local path, try to download it
    if (widget.resource.fileUrl != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = 'Downloading PDF file...';
      });

      try {
        // Check if we already have this file downloaded
        final fileName = widget.resource.fileName ??
            '${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Try to download the file
        final localPath = await _pdfService.downloadPdf(
          widget.resource.fileUrl!,
          fileName,
        );

        if (localPath != null) {
          setState(() {
            _localFilePath = localPath;
          });
          _verifyLocalFile(localPath);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to download PDF file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error downloading PDF: $e';
          _isLoading = false;
        });
      }
      return;
    }

    // If we have neither a file path nor a URL, show an error
    setState(() {
      _hasError = true;
      _errorMessage = 'No PDF file available';
      _isLoading = false;
    });
  }

  void _verifyLocalFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'File does not exist: $filePath';
          _isLoading = false;
        });
        return;
      }

      final fileSize = file.lengthSync();
      debugPrint('PDF file exists. Size: ${_formatFileSize(fileSize)} bytes');

      if (fileSize < 100) {
        // Very small file, probably empty or corrupted
        setState(() {
          _hasError = true;
          _errorMessage =
              'File appears to be invalid or corrupt (${_formatFileSize(fileSize)})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error accessing file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.resource.title,
          style: TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _prepareFile();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final effectiveFilePath = _localFilePath ?? widget.filePath;

    if (effectiveFilePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text('PDF file path is missing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Try downloading the file again',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: effectiveFilePath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (_pages) {
            setState(() {
              _totalPages = _pages!;
              _isLoading = false;
            });
            debugPrint('PDF rendered successfully. Total pages: $_totalPages');
          },
          onError: (error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'PDF rendering error: $error';
              _isLoading = false;
            });
            debugPrint('Error loading PDF: $error');
          },
          onPageError: (page, error) {
            debugPrint('Error loading page $page: $error');
          },
          onViewCreated: (PDFViewController pdfViewController) {
            debugPrint('PDF view controller created');
          },
          onPageChanged: (int? page, int? total) {
            if (page != null) {
              setState(() {
                _currentPage = page;
              });
            }
          },
        ),
        _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF...',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }

  Widget _buildBottomBar() {
    final effectiveFilePath = _localFilePath ?? widget.filePath;

    if (effectiveFilePath == null || _hasError || _isLoading) {
      return SizedBox(height: 0);
    }

    return BottomAppBar(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(fontSize: 10),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
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
                    SnackBar(content: Text('Use pinch gesture to zoom')),
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
                    SnackBar(content: Text('Use pinch gesture to zoom')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
