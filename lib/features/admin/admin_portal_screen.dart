import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  late Future<AdminData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<AdminData> _loadData() async {
    if (!await AdminService.isCurrentUserAdmin()) {
      if (mounted)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/auth');
        });
      throw StateError('Admin access required.');
    }
    final results = await Future.wait([
      AdminService.getProfiles(),
      AdminService.getAllHistory(),
    ]);
    return AdminData(
      profiles: results[0] as List<AdminProfile>,
      history: results[1] as List<AdminHistoryRecord>,
    );
  }

  Future<void> _reload() async {
    setState(() => _dataFuture = _loadData());
    await _dataFuture;
  }

  Future<void> _deleteProfile(AdminProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'Delete ${profile.name.isEmpty ? profile.email : profile.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AdminService.deleteProfile(profile.id);
      if (mounted) {
        setState(() => _dataFuture = _loadData());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile deleted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this profile.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AdminService.logout();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<AdminData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Could not load profiles'),
              ),
            );
          }
          final data = snapshot.data;
          final profiles = data?.profiles ?? const <AdminProfile>[];
          final historyByUser = <String, List<AdminHistoryRecord>>{};
          for (final record in data?.history ?? const <AdminHistoryRecord>[]) {
            historyByUser.putIfAbsent(record.userId, () => []).add(record);
          }
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final history = historyByUser[profile.id] ?? const [];
                final totalFare = history.fold<double>(
                  0,
                  (total, record) => total + record.trip.totalFare,
                );
                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name.substring(0, 1).toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      profile.name.isEmpty ? 'Unnamed profile' : profile.name,
                    ),
                    subtitle: Text(
                      '${profile.email}\n'
                      '${profile.authProvider} • ${history.length} trips • '
                      '৳${totalFare.toStringAsFixed(2)}',
                    ),
                    children: [
                      for (final record in history)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.directions_bus_outlined),
                          title: Text(record.trip.formattedFare),
                          subtitle: Text(
                            '${record.trip.formattedDate} • '
                            '${record.trip.formattedDistance}',
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Delete profile',
                          onPressed: () => _deleteProfile(profile),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminData {
  final List<AdminProfile> profiles;
  final List<AdminHistoryRecord> history;

  const AdminData({required this.profiles, required this.history});
}
