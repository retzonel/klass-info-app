import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../models/file_model.dart';
import '../services/file_service.dart';
import 'package:open_filex/open_filex.dart';

class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({super.key});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  final FileService _fileService = FileService();

  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  File? _localFile;
  String? _errorMessage;

  late FileModel _file;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _file = ModalRoute.of(context)!.settings.arguments as FileModel;
      _checkLocalFile();
    }
  }

  Future<void> _checkLocalFile() async {
    final alreadyDownloaded = await _fileService.isDownloaded(_file);
    if (!mounted) return;

    if (alreadyDownloaded) {
      // Already on disk — resolve path silently and show "open" state
      final file = await _fileService.getOrDownloadFile(
        _file,
        onProgress: (_) {},
      );
      if (!mounted) return;
      setState(() {
        _localFile = file;
        _state = _DownloadState.done;
      });
    } else {
      setState(() => _state = _DownloadState.idle);
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final file = await _fileService.getOrDownloadFile(
        _file,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _localFile = file;
        _state = _DownloadState.done;
      });
      // Immediately open after download, just like WhatsApp
      await _openFile();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _DownloadState.error;
        _errorMessage = 'Download failed. Check your connection.';
      });
    }
  }

  // Replace the entire _openFile method:
  Future<void> _openFile() async {
    if (_localFile == null) return;

    final result = await OpenFilex.open(_localFile!.path);

    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to open this file type.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          _file.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FileTypeIcon(file: _file),
              const SizedBox(height: 24),
              Text(
                _file.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _file.fileType.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              _buildAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    return switch (_state) {
      _DownloadState.idle => _ActionButton(
        icon: Icons.download_rounded,
        label: 'Download',
        onTap: _startDownload,
      ),
      _DownloadState.downloading => _ProgressRing(progress: _progress),
      _DownloadState.done => _ActionButton(
        icon: Icons.open_in_new_rounded,
        label: 'Open',
        onTap: _openFile,
        subtitle: 'Saved on your device',
      ),
      _DownloadState.error => Column(
        children: [
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.refresh_rounded,
            label: 'Try Again',
            onTap: _startDownload,
          ),
        ],
      ),
    };
  }
}

// ─── Supporting widgets ──────────────────────────────────────────────────────

enum _DownloadState { idle, downloading, done, error }

class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.file});
  final FileModel file;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: 88,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          file.displayType,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon),
          label: Text(label),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          width: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.15),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Downloading…',
          style: TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      ],
    );
  }
}
