import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../services/gemini_service.dart';
import '../emergency/emergency_screen.dart';
import '../../widgets/guest_guard.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final tripState = ref.watch(tripProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authState.user;
    final isGuest = authState.isGuestMode;
    final trips = tripState.trips;

    final totalKm = trips.fold<double>(0, (s, t) => s + t.totalDistanceKm);
    final totalFareAmt = trips.fold<double>(0, (s, t) => s + t.totalFare);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, user, isGuest),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    if (isGuest) ...[
                      _buildGuestBanner(context, isDark, ref),
                      const SizedBox(height: 24),
                    ],
                    _buildStatsRow(isDark, trips.length, totalKm, totalFareAmt),
                    const SizedBox(height: 24),
                    _buildMenuSection(context, isDark, ref, themeMode, isGuest),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UserModel? user, bool isGuest) {
    final name = isGuest
        ? 'Guest User'
        : (user?.name ?? AppStrings.guestUser);
    final email = user?.email;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              Text(
                AppStrings.profile,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: AppConstants.fontBengali,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: AppConstants.fontBengali,
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 4),
            Text(
              'Using FareTrackBD as a Guest',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ] else if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (user != null && !isGuest) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.memberSince} ${_formatDate(user.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                fontFamily: AppConstants.fontBengali,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      bool isDark, int tripCount, double totalKm, double totalFare) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.directions_bus_rounded,
              AppStrings.totalTrips,
              '$tripCount',
              AppConstants.primaryAccent,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.straighten_rounded,
              AppStrings.totalDistance,
              '${totalKm.toStringAsFixed(1)} ${AppStrings.km}',
              AppConstants.successGreen,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.monetization_on_rounded,
              AppStrings.totalFare,
              '${AppStrings.bdt}${totalFare.toStringAsFixed(0)}',
              AppConstants.fareAmber,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context, bool isDark, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.1),
            const Color(0xFF3B82F6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 32,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          Text(
            'You are using FareTrackBD as a Guest.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to unlock all features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).exitGuestMode();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: AppConstants.fontBengali,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value,
      Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: AppConstants.fontEnglish,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isDark,
      WidgetRef ref, ThemeMode themeMode, bool isGuest) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          if (isGuest) ...[
            _buildMenuItem(
              icon: Icons.login_rounded,
              title: 'Sign In',
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: () async {
                await ref.read(authProvider.notifier).exitGuestMode();
                if (context.mounted) context.go('/auth');
              },
            ),
            _buildDivider(isDark),
          ],
          if (!isGuest) ...[
            _buildMenuItem(
              icon: Icons.history_rounded,
              title: AppStrings.historyTitle,
              color: AppConstants.primaryAccent,
              isDark: isDark,
              onTap: () {
                context.pop();
                context.push('/history');
              },
            ),
            _buildDivider(isDark),
          ],
          _buildMenuItem(
            icon: Icons.smart_toy_outlined,
            title: 'AI Fare Assistant',
            color: const Color(0xFF1D9E75),
            isDark: isDark,
            onTap: () {
              guardRestrictedAction(context, ref);
              if (!isGuest) {
                context.pop();
                context.push('/ai-assistant');
              }
            },
          ),
          _buildDivider(isDark),
          if (!isGuest) ...[
            _buildMenuItem(
              icon: Icons.key_rounded,
              title: 'AI API Key',
              color: const Color(0xFF9C27B0),
              isDark: isDark,
              onTap: () => _showApiKeyDialog(context),
            ),
            _buildDivider(isDark),
          ],
          _buildMenuItem(
            icon: Icons.map_outlined,
            title: 'Accident Map',
            color: const Color(0xFF378ADD),
            isDark: isDark,
            onTap: () {
              context.pop();
              context.push('/accident-map');
            },
          ),
          _buildDivider(isDark),
          _buildMenuItem(
            icon: Icons.sos_rounded,
            title: 'SOS Settings',
            color: Colors.redAccent,
            isDark: isDark,
            onTap: () {
              context.pop();
              context.push('/sos-settings');
            },
          ),
          _buildDivider(isDark),
          _buildThemeToggle(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            title: AppStrings.darkMode,
            isDark: isDark,
            value: isDark,
            onToggle: (_) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          _buildDivider(isDark),
          _buildMenuItem(
            icon: Icons.emergency_rounded,
            title: AppStrings.emergency,
            color: AppConstants.errorRed,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyScreen()),
              );
            },
          ),
          _buildDivider(isDark),
          if (isGuest)
            _buildMenuItem(
              icon: Icons.person_add_rounded,
              title: 'Sign Up',
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: () async {
                await ref.read(authProvider.notifier).exitGuestMode();
                if (context.mounted) context.go('/auth');
              },
            )
          else
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: AppStrings.signOut,
              color: AppConstants.errorRed,
              isDark: isDark,
              onTap: () => _confirmSignOut(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: AppConstants.fontBengali,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle({
    required IconData icon,
    required String title,
    required bool isDark,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppConstants.fareAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppConstants.fareAmber,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppConstants.primaryGreen,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppStrings.signOut,
          style: const TextStyle(fontFamily: AppConstants.fontBengali),
        ),
        content: Text(
          'আপনি কি সাইন আউট করতে চান?',
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.deleteNo,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
              context.go('/auth');
            },
            child: Text(
              AppStrings.signOut,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: GeminiService.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, size: 22, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('AI API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আপনার Gemini API Key দিন।',
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'API Key পেতে https://aistudio.google.com/apikey তে যান।',
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'API Key',
                hintStyle: TextStyle(
                    color: Colors.grey[400], fontFamily: AppConstants.fontBengali),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                    }
                  },
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GeminiService.hasApiKey
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    GeminiService.hasApiKey
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: GeminiService.hasApiKey ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    GeminiService.hasApiKey
                        ? 'API Key সেট করা আছে'
                        : 'কোনো API Key সেট করা নেই',
                    style: TextStyle(
                      fontFamily: AppConstants.fontBengali,
                      fontSize: 12,
                      color:
                          GeminiService.hasApiKey ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              GeminiService.clearApiKey();
              Navigator.pop(ctx);
            },
            child: Text('মুছুন',
                style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.red.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('বাতিল',
                style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[500])),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await GeminiService.setApiKey(key);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
