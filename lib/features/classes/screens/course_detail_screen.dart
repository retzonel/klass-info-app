import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../announcements/models/announcement_model.dart';
import '../../announcements/services/announcement_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/course_model.dart';
import '../../files/models/file_model.dart';
import '../../files/services/file_service.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
    final user = context.read<DashboardProvider>().user;
    final isAdmin = user?.isAdmin ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          foregroundColor: AppColors.textDark,
          title: Text(
            course.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Announcements'),
              Tab(icon: Icon(Icons.folder_outlined), text: 'Files'),
            ],
          ),
        ),
        floatingActionButton: isAdmin ? _AdminFab(course: course) : null,
        body: TabBarView(
          children: [
            _AnnouncementsTab(
              course: course,
              isAdmin: isAdmin,
            ), // ← isAdmin passed here
            _FilesTab(course: course),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANNOUNCEMENTS TAB
// ─────────────────────────────────────────────────────────────

class _AnnouncementsTab extends StatefulWidget {
  final CourseModel course;
  final bool isAdmin;

  const _AnnouncementsTab({required this.course, required this.isAdmin});

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _service = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AnnouncementModel>>(
      stream: _service.announcementsStream(widget.course.classCode, widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load announcements.'));
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No announcements yet.',
                  style: TextStyle(fontSize: 15, color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: announcements.length,
          itemBuilder: (context, index) =>
              _buildAnnouncementCard(announcements[index]),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(announcement.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );

    if (!widget.isAdmin) return card;

    return Slidable(
      key: ValueKey(announcement.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(announcement),
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: card,
    );
  }

  Future<void> _confirmDelete(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text('"${announcement.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await _service.deleteAnnouncement(
        classCode: widget.course.classCode,
        courseId: widget.course.id,
        announcementId: announcement.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// FILES TAB  (unchanged)
// ─────────────────────────────────────────────────────────────

class _FilesTab extends StatelessWidget {
  final CourseModel course;
  const _FilesTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final service = FileService();
    final user = context.read<DashboardProvider>().user;
    final isAdmin = user?.isAdmin ?? false;

    return StreamBuilder<List<FileModel>>(
      stream: service.filesStream(course.classCode, course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load files.'));
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No files uploaded yet.',
                  style: TextStyle(fontSize: 15, color: AppColors.textLight),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the upload button to add files.',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: files.length,
          itemBuilder: (context, index) =>
              _buildFileCard(context, files[index]),
        );
      },
    );
  }

  Widget _buildFileCard(BuildContext context, FileModel file) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.fileViewer, arguments: file);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _fileColor(file.fileType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  file.displayType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _fileColor(file.fileType),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(file.uploadedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Color _fileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// ADMIN FAB  (unchanged)
// ─────────────────────────────────────────────────────────────

class _AdminFab extends StatefulWidget {
  final CourseModel course;
  const _AdminFab({required this.course});

  @override
  State<_AdminFab> createState() => _AdminFabState();
}

class _AdminFabState extends State<_AdminFab> {
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _uploadFile(BuildContext context) async {
    final service = FileService();
    final user = context.read<DashboardProvider>().user;

    final picked = await service.pickFile();
    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await service.uploadFile(
        classCode: widget.course.classCode,
        courseId: widget.course.id,
        uploadedBy: user!.uid,
        pickedFile: picked,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final isAnnouncementsTab = tabController.index == 0;
        final isFilesTab = tabController.index == 1;

        if (isAnnouncementsTab) {
          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.postAnnouncement,
              arguments: widget.course,
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Post'),
          );
        }

        if (isFilesTab) {
          return _isUploading
              ? FloatingActionButton.extended(
                  onPressed: null,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  icon: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      value: _uploadProgress,
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  label: Text('${(_uploadProgress * 100).toInt()}%'),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _uploadFile(context),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
