import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailImage extends StatefulWidget {
  final String videoPath;
  final BoxFit fit;

  const VideoThumbnailImage({
    super.key,
    required this.videoPath,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoThumbnailImage> createState() => _VideoThumbnailImageState();
}

class _VideoThumbnailImageState extends State<VideoThumbnailImage> {
  String? _thumbnailPath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String fileName = widget.videoPath.split('/').last.replaceAll('.mp4', '_thumb.jpg');
      final String cachePath = '${tempDir.path}/$fileName';

      final File cachedFile = File(cachePath);
      if (await cachedFile.exists()) {
        if (mounted) {
          setState(() {
            _thumbnailPath = cachePath;
            _isLoading = false;
          });
        }
        return;
      }

      String sourcePath = widget.videoPath;
      if (widget.videoPath.startsWith('assets/')) {
        // Need to extract asset to temp file first for video_thumbnail to read it
        final ByteData data = await rootBundle.load(widget.videoPath);
        final File assetTempFile = File('${tempDir.path}/${widget.videoPath.split('/').last}');
        await assetTempFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        sourcePath = assetTempFile.path;
      }

      final String? generatedPath = await VideoThumbnail.thumbnailFile(
        video: sourcePath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (mounted) {
        setState(() {
          if (generatedPath != null) {
            _thumbnailPath = generatedPath;
          } else {
            _hasError = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      debugPrint("DreadmoorOS ✗ VideoThumbnail Error: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _thumbnailPath == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54),
        ),
      );
    }

    return Image.file(
      File(_thumbnailPath!),
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  }
}
