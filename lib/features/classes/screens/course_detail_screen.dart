import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../announcements/models/announcement_model.dart';
import '../../announcements/services/announcement_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/course_model.dart';

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
         
        floatingActionButton: isAdmin
            ? _AdminFab(course: course)
            : null,
        body: TabBarView(
          children: [
            _AnnouncementsTab(course: course),
            _FilesTab(course: course),             
          ],
        ),
      ),
    );
  }
}

 

class _AnnouncementsTab extends StatelessWidget {
  final CourseModel course;
  const _AnnouncementsTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService();

    return StreamBuilder<List<AnnouncementModel>>(
      stream: service.announcementsStream(course.classCode, course.id),
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
                Icon(Icons.campaign_outlined,
                    size: 64, color: Colors.grey.shade300),
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
    return Container(
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

 

class _FilesTab extends StatelessWidget {
  final CourseModel course;
  const _FilesTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Files coming soon.',
            style: TextStyle(fontSize: 15, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

 

class _AdminFab extends StatefulWidget {
  final CourseModel course;
  const _AdminFab({required this.course});

  @override
  State<_AdminFab> createState() => _AdminFabState();
}

class _AdminFabState extends State<_AdminFab> {
  @override
  Widget build(BuildContext context) {
     
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final isAnnouncementsTab = tabController.index == 0;
        return isAnnouncementsTab
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.postAnnouncement,
                    arguments: widget.course,
                  );
                },
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.add),
                label: const Text('Post'),
              )
            : const SizedBox.shrink();
      },
    );
  }
}