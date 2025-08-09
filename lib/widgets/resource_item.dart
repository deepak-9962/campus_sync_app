import 'package:flutter/material.dart';
import '../models/resource.dart';

class ResourceItem extends StatefulWidget {
  final Resource resource;
  final Function(Resource) onDownload;
  final Function(Resource) onPreview;
  
  // Flag to indicate if resource is currently downloading
  bool _isDownloading = false;
  
  bool get isDownloading => _isDownloading;
  
  set isDownloading(bool value) {
    _isDownloading = value;
  }

  ResourceItem({
    Key? key, 
    required this.resource, 
    required this.onDownload, 
    required this.onPreview
  }) : super(key: key);

  @override
  _ResourceItemState createState() => _ResourceItemState();
}

class _ResourceItemState extends State<ResourceItem> {
  late Color _iconColor;
  late IconData _iconData;

  @override
  void initState() {
    super.initState();
    _setIconByFileType();
  }

  void _setIconByFileType() {
    switch (widget.resource.fileType.toLowerCase()) {
      case 'pdf':
        _iconData = Icons.picture_as_pdf;
        _iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        _iconData = Icons.description;
        _iconColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        _iconData = Icons.table_chart;
        _iconColor = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        _iconData = Icons.slideshow;
        _iconColor = Colors.orange;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        _iconData = Icons.image;
        _iconColor = Colors.purple;
        break;
      case 'txt':
        _iconData = Icons.article;
        _iconColor = Colors.grey;
        break;
      default:
        _iconData = Icons.insert_drive_file;
        _iconColor = Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onPreview(widget.resource),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconData,
                  color: _iconColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.resource.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.resource.subject} • ${widget.resource.semester}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.resource.fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.resource.fileSize,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Spacer(),
                        Text(
                          widget.resource.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: widget.isDownloading 
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      )
                    : Icon(Icons.download_rounded, color: Theme.of(context).primaryColor),
                onPressed: () {
                  if (!widget.isDownloading) {
                    widget.onDownload(widget.resource);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
