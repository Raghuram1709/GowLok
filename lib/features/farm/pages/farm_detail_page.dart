import 'package:flutter/material.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/global_nav_controller.dart';
import '../farm_context.dart';
import '../services/farm_service.dart';

class FarmDetailPage extends StatefulWidget {
  final FarmContext farm;

  const FarmDetailPage({Key? key, required this.farm}) : super(key: key);

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  late String _farmName;
  late bool _isAdmin;
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _farmName = widget.farm.farmName;
    _isAdmin = widget.farm.role.toLowerCase() == 'admin';
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      final workers = await FarmService.getWorkers(widget.farm.farmId);
      if (mounted) setState(() { _workers = workers; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load workers: ${_cleanError(e)}', isError: true);
      }
    }
  }

  String _cleanError(Object e) {
    final s = e.toString();
    final match = RegExp(r'message:\s*(.+?)(?:,|\))').firstMatch(s);
    return match?.group(1)?.trim() ?? s;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        ));
    });
  }

  // ── Edit Farm Name ──────────────────────────────────────────
  Future<void> _editFarmName() async {
    if (!mounted) return;

    final newName = await showDialog<String>(
      context: context,
      builder: (dCtx) => _EditNameDialog(initialName: _farmName),
    );

    if (!mounted) return;
    if (newName == null || newName.isEmpty || newName == _farmName) return;

    try {
      await FarmService.updateFarmName(widget.farm.farmId, newName);
      if (!mounted) return;
      setState(() => _farmName = newName);
      _showSnack('Farm name updated');
    } catch (e) {
      if (mounted) _showSnack('Failed to update: ${_cleanError(e)}', isError: true);
    }
  }

  // ── Add Worker ──────────────────────────────────────────────
  Future<void> _addWorker() async {
    if (!mounted) return;

    final email = await showDialog<String>(
      context: context,
      builder: (dCtx) => const _AddWorkerDialog(),
    );

    if (!mounted) return;
    if (email == null || email.isEmpty) return;

    try {
      await FarmService.addWorker(widget.farm.farmId, email);
      if (!mounted) return;
      _showSnack('Worker added successfully');
      _loadWorkers();
    } catch (e) {
      if (mounted) _showSnack(_cleanError(e), isError: true);
    }
  }

  // ── Remove Worker ───────────────────────────────────────────
  Future<void> _removeWorker(Map<String, dynamic> worker) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Remove Worker'),
        content: Text('Remove ${worker['email']} from this farm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GowlokColors.critical),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await FarmService.removeWorker(widget.farm.farmId, worker['user_id']);
      if (!mounted) return;
      _showSnack('Worker removed');
      _loadWorkers();
    } catch (e) {
      if (mounted) _showSnack(_cleanError(e), isError: true);
    }
  }

  // ── Delete Farm ─────────────────────────────────────────────
  Future<void> _deleteFarm() async {
    if (!mounted) return;

    final first = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Farm'),
        content: const Text(
          'This will permanently delete the farm, all cattle, health records, '
          'alerts, and remove all workers. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GowlokColors.critical),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || first != true) return;

    final second = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => _DeleteConfirmDialog(farmName: _farmName),
    );

    if (!mounted || second != true) return;

    try {
      await FarmService.deleteFarm(widget.farm.farmId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) _showSnack('Failed to delete: ${_cleanError(e)}', isError: true);
    }
  }

  // ── BUILD ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Farm')),
      bottomNavigationBar: _buildBottomNav(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkers,
              child: ListView(
                padding: const EdgeInsets.all(GowlokSpacing.md),
                children: _buildChildren(isDark),
              ),
            ),
    );
  }

  Widget _buildBottomNav() {
    return ValueListenableBuilder<int>(
      valueListenable: GlobalNavController.selectedIndex,
      builder: (ctx, index, child) {
        return BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            GlobalNavController.selectedIndex.value = i;
          },
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: GowlokColors.primary,
          unselectedItemColor: GowlokColors.neutral600,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Farm'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Check'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
      },
    );
  }

  List<Widget> _buildChildren(bool isDark) {
    final children = <Widget>[];

    // ── Farm Name Header ──
    children.add(Card(
      child: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: GowlokColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
              ),
              child: const Icon(Icons.agriculture, color: GowlokColors.primary, size: 28),
            ),
            const SizedBox(width: GowlokSpacing.md),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_farmName, style: GowlokTextStyles.headline3),
                const SizedBox(height: 4),
                Text(
                  'Role: ${widget.farm.role.toUpperCase()}',
                  style: GowlokTextStyles.bodySmall.copyWith(
                    color: isDark ? GowlokColors.neutral400 : GowlokColors.neutral600,
                  ),
                ),
              ],
            )),
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.edit, color: GowlokColors.primary),
                onPressed: _editFarmName,
                tooltip: 'Edit farm name',
              ),
          ],
        ),
      ),
    ));

    children.add(const SizedBox(height: GowlokSpacing.lg));

    // ── Workers Section ──
    children.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Farm Members', style: GowlokTextStyles.headline3),
        if (_isAdmin)
          ElevatedButton.icon(
            onPressed: _addWorker,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Worker'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm, vertical: GowlokSpacing.xs),
            ),
          ),
      ],
    ));

    children.add(const SizedBox(height: GowlokSpacing.sm));

    if (_workers.isEmpty) {
      children.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(GowlokSpacing.lg),
          child: Center(child: Text('No members found',
            style: GowlokTextStyles.bodyMedium.copyWith(color: GowlokColors.neutral600),
          )),
        ),
      ));
    } else {
      for (final w in _workers) {
        final isOwner = w['role'] == 'admin';
        children.add(Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOwner
                  ? GowlokColors.primary.withValues(alpha: 0.15)
                  : GowlokColors.success.withValues(alpha: 0.15),
              child: Icon(
                isOwner ? Icons.admin_panel_settings : Icons.person,
                color: isOwner ? GowlokColors.primary : GowlokColors.success,
                size: 22,
              ),
            ),
            title: Text(w['email']?.toString() ?? '', style: GowlokTextStyles.bodyLarge),
            subtitle: Text(
              w['role']?.toString().toUpperCase() ?? '',
              style: GowlokTextStyles.labelSmall.copyWith(
                color: isOwner ? GowlokColors.primary : GowlokColors.success,
              ),
            ),
            trailing: (_isAdmin && !isOwner)
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: GowlokColors.critical),
                    onPressed: () => _removeWorker(w),
                    tooltip: 'Remove worker',
                  )
                : null,
          ),
        ));
      }
    }

    // ── Danger Zone ──
    if (_isAdmin) {
      children.add(const SizedBox(height: GowlokSpacing.lg));
      children.add(const SizedBox(height: GowlokSpacing.lg));
      children.add(Container(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: GowlokColors.critical, width: 1),
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danger Zone',
              style: GowlokTextStyles.headline3.copyWith(color: GowlokColors.critical)),
            const SizedBox(height: GowlokSpacing.xs),
            Text('Deleting a farm will permanently remove all cattle, health records, alerts, and members.',
              style: GowlokTextStyles.bodySmall.copyWith(
                color: isDark ? GowlokColors.neutral400 : GowlokColors.neutral600,
              )),
            const SizedBox(height: GowlokSpacing.md),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _deleteFarm,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Farm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GowlokColors.critical,
                foregroundColor: Colors.white,
              ),
            )),
          ],
        ),
      ));
    }

    children.add(const SizedBox(height: GowlokSpacing.lg));
    return children;
  }
}

// ═══════════════════════════════════════════════════════════════
// SELF-CONTAINED DIALOG WIDGETS
// Each creates & disposes its own TextEditingController internally.
// ═══════════════════════════════════════════════════════════════

class _EditNameDialog extends StatefulWidget {
  final String initialName;
  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Farm Name'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Farm Name'),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddWorkerDialog extends StatefulWidget {
  const _AddWorkerDialog();

  @override
  State<_AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends State<_AddWorkerDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Worker'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the email of an existing user to add them as a worker.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'worker@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  final String farmName;
  const _DeleteConfirmDialog({required this.farmName});

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you sure?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Type "${widget.farmName}" to confirm deletion.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(labelText: 'Farm name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: GowlokColors.critical),
          onPressed: () {
            if (_ctrl.text.trim() == widget.farmName) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Confirm Delete'),
        ),
      ],
    );
  }
}
