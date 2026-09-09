import 'package:flutter/material.dart';
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
      if (mounted) context.go('/auth');
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

  Future<void> _setBanned(AdminProfile profile) async {
    try {
      await AdminService.setBanned(profile.id, !profile.banned);
      await _reload();
    } catch (_) {
      _show('অ্যাকাউন্টের অবস্থা পরিবর্তন করা যায়নি');
    }
  }

  Future<void> _deleteProfile(AdminProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অ্যাকাউন্ট মুছবেন?'),
        content: Text(
          '${profile.name.isEmpty ? profile.email : profile.name}-এর প্রোফাইল ও ইতিহাস মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.deleteProfile(profile.id);
      await _reload();
    } catch (_) {
      _show('অ্যাকাউন্ট মুছে ফেলা যায়নি');
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাডমিন প্যানেল'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await AdminService.logout();
              if (!context.mounted) return;
              context.go('/auth');
            },
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
              child: FilledButton(
                onPressed: _reload,
                child: const Text('আবার চেষ্টা করুন'),
              ),
            );
          }
          final data = snapshot.data!;
          final historyByUser = <String, int>{};
          for (final record in data.history) {
            historyByUser.update(
              record.userId,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
          if (data.profiles.isEmpty) {
            return const Center(child: Text('কোনো ব্যবহারকারী নেই'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.profiles.length,
              itemBuilder: (context, index) {
                final profile = data.profiles[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      profile.name.isEmpty ? profile.email : profile.name,
                    ),
                    subtitle: Text(
                      '${profile.email}\nইতিহাস: ${historyByUser[profile.id] ?? 0}টি',
                    ),
                    isThreeLine: true,
                    leading: Icon(profile.banned ? Icons.block : Icons.person),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'ban') _setBanned(profile);
                        if (value == 'delete') _deleteProfile(profile);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'ban',
                          child: Text(profile.banned ? 'আনব্যান' : 'ব্যান'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('ডেটা মুছুন'),
                        ),
                      ],
                    ),
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
