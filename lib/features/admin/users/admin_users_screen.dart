import 'package:flutter/material.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/user_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = UserRepository();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final users = await _repo.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(user.name.isEmpty ? 'Unnamed' : user.name,
                              style: context.textTheme.titleSmall),
                        ),
                        if (user.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Admin',
                                style: TextStyle(
                                    fontSize: 10, color: Theme.of(context).colorScheme.primary)),
                          ),
                      ],
                    ),
                    subtitle: Text(user.email,
                        style: context.textTheme.bodySmall),
                    trailing: user.isAdmin
                        ? null
                        : TextButton(
                            onPressed: () async {
                              await _repo.toggleBan(user.id, !user.isBanned);
                              _load();
                            },
                            child: Text(
                              user.isBanned ? 'Unban' : 'Ban',
                              style: TextStyle(
                                color: user.isBanned
                                    ? const Color(0xFF2ED573)
                                    : const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                  );
                },
              ),
            ),
    );
  }
}
