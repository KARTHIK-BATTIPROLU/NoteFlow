import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/toast.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../home/presentation/screens/downloads_screen.dart';
import 'edit_profile_screen.dart';

// Provider for user stats
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return UserStats(uploads: 0, downloads: 0, subjects: 0);
  }

  try {
    final apiService = ApiService();
    final allResources = await apiService.getAllResources();
    
    // Filter resources by current user's firebase_uid
    final userUploads = allResources
        .where((resource) => resource.firebaseUid == user.uid)
        .toList();
    
    // Get downloads from Hive
    final downloads = LocalDb.getAllDownloads();
    
    // Get unique subjects from downloads
    final uniqueSubjects = <String>{};
    for (var download in downloads) {
      final subjectId = download['subject_id'] ?? download['subjectId'];
      if (subjectId != null) {
        uniqueSubjects.add(subjectId.toString());
      }
    }
    
    return UserStats(
      uploads: userUploads.length,
      downloads: downloads.length,
      subjects: uniqueSubjects.length,
    );
  } catch (e) {
    return UserStats(uploads: 0, downloads: 0, subjects: 0);
  }
});

class UserStats {
  final int uploads;
  final int downloads;
  final int subjects;

  UserStats({
    required this.uploads,
    required this.downloads,
    required this.subjects,
  });
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  String _formatMemberSince(DateTime? creationTime) {
    if (creationTime == null) return 'Recently';
    return DateFormat('MMMM yyyy').format(creationTime);
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    Toast.show(context, '$feature coming soon!');
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (e) {
                if (context.mounted) {
                  Toast.show(context, 'Error signing out: $e', isError: true);
                }
              }
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final statsAsync = ref.watch(userStatsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            title: Text(
              'Profile',
              style: AppTextStyles.headingMedium,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Card
                  _buildProfileHeader(context, ref, user),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats Row
                  statsAsync.when(
                    data: (stats) => _buildStatsRow(context, stats),
                    loading: () => _buildStatsRowLoading(context),
                    error: (_, __) => _buildStatsRow(
                      context,
                      UserStats(uploads: 0, downloads: 0, subjects: 0),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Appearance Section
                  _buildAppearanceSection(context, ref, themeMode),

                  const SizedBox(height: AppSpacing.lg),

                  // About Section
                  _buildAboutSection(context),

                  const SizedBox(height: AppSpacing.lg),

                  // Account Section (Danger Zone)
                  _buildAccountSection(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              image: user?.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(user!.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.photoURL == null
                ? Center(
                    child: Text(
                      _getInitials(user?.email),
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: AppSpacing.md),

          // Display Name (if available)
          if (user?.displayName != null && user!.displayName!.isNotEmpty) ...[
            Text(
              user.displayName!,
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Email
          Text(
            user?.email ?? 'No email',
            style: user?.displayName != null && user!.displayName!.isNotEmpty
                ? AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  )
                : AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Member Since
          Text(
            'Member since ${_formatMemberSince(user?.metadata.creationTime)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                // Refresh if profile was updated
                if (result == true && context.mounted) {
                  ref.invalidate(userStatsProvider);
                  ref.invalidate(authStateProvider);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, UserStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            icon: Icons.upload_rounded,
            label: 'Uploads',
            value: stats.uploads.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            icon: Icons.download_rounded,
            label: 'Downloads',
            value: stats.downloads.toString(),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            icon: Icons.school_rounded,
            label: 'Subjects',
            value: stats.subjects.toString(),
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCardSkeleton(context)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildStatCardSkeleton(context)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildStatCardSkeleton(context)),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'APPEARANCE',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'Theme',
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: Text(
              themeMode == ThemeMode.dark
                  ? 'Dark'
                  : themeMode == ThemeMode.light
                      ? 'Light'
                      : 'System',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: PopupMenuButton<ThemeMode>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              onSelected: (ThemeMode mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        color: themeMode == ThemeMode.light
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Light',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: themeMode == ThemeMode.light
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: themeMode == ThemeMode.light
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (themeMode == ThemeMode.light) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode_rounded,
                        color: themeMode == ThemeMode.dark
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Dark',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: themeMode == ThemeMode.dark
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: themeMode == ThemeMode.dark
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (themeMode == ThemeMode.dark) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(
                        Icons.brightness_auto_rounded,
                        color: themeMode == ThemeMode.system
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'System',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: themeMode == ThemeMode.system
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: themeMode == ThemeMode.system
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (themeMode == ThemeMode.system) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'ABOUT',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.download_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'My Downloads',
              style: AppTextStyles.bodyLarge,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DownloadsScreen(),
                ),
              );
            },
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor, indent: 56),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: AppColors.primary,
            ),
            title: Text(
              'App Version',
              style: AppTextStyles.bodyLarge,
            ),
            trailing: Text(
              'v1.0.0',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor, indent: 56),
          ListTile(
            leading: Icon(
              Icons.share_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'Share App',
              style: AppTextStyles.bodyLarge,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => _showComingSoonSnackBar(context, 'Share app'),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor, indent: 56),
          ListTile(
            leading: Icon(
              Icons.star_outline,
              color: AppColors.primary,
            ),
            title: Text(
              'Rate App',
              style: AppTextStyles.bodyLarge,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => _showComingSoonSnackBar(context, 'Rate app'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'ACCOUNT',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: AppColors.error,
            ),
            title: Text(
              'Sign Out',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.error,
            ),
            onTap: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
    );
  }
}


