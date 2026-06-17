import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/models/class_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

     
     
    final uid = context.read<AuthProvider>().currentUser!.uid;
     
     
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init(uid);
    });
  }

  Future<void> _logout() async {
    context.read<DashboardProvider>().reset();  
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final user = dashboard.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'KlassInfo',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textLight),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: dashboard.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final uid = context.read<AuthProvider>().currentUser!.uid;
                context.read<DashboardProvider>().init(uid);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(user?.displayName ?? 'Student'),
                  ),
                  SliverToBoxAdapter(child: _buildSectionTitle('Your Classes')),
                  dashboard.classes.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildClassCard(dashboard.classes[index]),
                            childCount: dashboard.classes.length,
                          ),
                        ),
                   
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.joinClass).then((_) {
               
               
              final uid = context.read<AuthProvider>().currentUser?.uid;
              if (uid != null && mounted) {
                context.read<DashboardProvider>().init(uid);
              }
            }),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Join Class'),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
           
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'ll get notified when admins post announcements.',
                    style: TextStyle(fontSize: 13, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.classDetail,
          arguments: classModel,
        );
      },
      child: Container(
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
        child: Row(
          children: [
             
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.class_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classModel.classCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "You haven't joined any classes yet.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Join Class" below to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
