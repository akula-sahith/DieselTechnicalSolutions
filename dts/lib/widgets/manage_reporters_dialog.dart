import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../repositories/auth_repository.dart';

class ManageReportersDialog extends ConsumerStatefulWidget {
  const ManageReportersDialog({super.key});

  @override
  ConsumerState<ManageReportersDialog> createState() => _ManageReportersDialogState();
}

class _ManageReportersDialogState extends ConsumerState<ManageReportersDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isCreating = false;
  List<UserModel> _reporters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReporters();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReporters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final reporters = await repo.getReporters();
      if (mounted) {
        setState(() {
          _reporters = reporters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createReporter() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.registerReporter(name: name, email: email, password: password);

      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporter credentials created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _fetchReporters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create reporter: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _deleteReporter(UserModel reporter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reporter Credentials'),
        content: Text('Are you sure you want to delete access for "${reporter.name}" (${reporter.email})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(authRepositoryProvider);
        await repo.deleteReporter(reporter.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporter deleted successfully.'), backgroundColor: AppColors.success),
          );
        }
        await _fetchReporters();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.admin_panel_settings, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Manage Reporters', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Reporter Credentials',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reporter Full Name *',
                  prefixIcon: Icon(Icons.person),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Reporter Email *',
                  prefixIcon: Icon(Icons.email),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isCreating ? null : _createReporter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _isCreating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add),
                label: const Text('Create Credentials'),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registered Reporters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchReporters,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_error != null)
                Text('Error: $_error', style: const TextStyle(color: AppColors.error, fontSize: 12))
              else if (_reporters.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No reporters registered yet.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reporters.length,
                  itemBuilder: (context, index) {
                    final r = _reporters[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(r.email, style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () => _deleteReporter(r),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
