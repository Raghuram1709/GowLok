import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gowlok/core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/locale/app_translations.dart';
import '../../core/locale/locale_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedScale({required Widget child, required double delay}) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _enterController,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOutBack),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _enterController,
          curve: Interval(delay, delay + 0.3, curve: Curves.easeIn),
        ),
        child: child,
      ),
    );
  }

  Widget _buildAnimatedSlide({required Widget child, required double delay}) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _enterController,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _enterController,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeIn),
        ),
        child: child,
      ),
    );
  }

  Future<void> _pickAndUploadImage(AuthProvider authProvider) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading avatar...')),
        );
      }
      
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = 'avatar_$userId.${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      // Upload to Supabase Storage matching the SQL provided earlier
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        fileName, 
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );
      
      final String publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      
      // Update Auth Metadata
      await authProvider.updateAvatar(publicUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final avatarUrl = authProvider.user?.userMetadata?['avatar_url'] as String?;

    return Consumer<LocaleController>(
      builder: (context, localeCtrl, _) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: GowlokSpacing.lg,
              right: GowlokSpacing.lg,
              top: GowlokSpacing.lg * 2,
              bottom: 100, // padding for bottom navbar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAnimatedScale(
                  delay: 0.0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(authProvider),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [GowlokColors.primary.withOpacity(0.5), GowlokColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GowlokColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? GowlokColors.neutral800 : Colors.white,
                            image: avatarUrl != null && avatarUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 64,
                                  color: isDark ? GowlokColors.neutral300 : GowlokColors.neutral600,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg),
                _buildAnimatedSlide(
                  delay: 0.2,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            authProvider.user?.userMetadata?['full_name'] ?? tr(context, 'user_profile'),
                            style: GowlokTextStyles.headline2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showEditProfileSheet(context, authProvider),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: GowlokColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _pulseAnimation,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: GowlokColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: GowlokColors.success,
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Online",
                            style: GowlokTextStyles.bodyMedium.copyWith(
                              color: isDark ? GowlokColors.neutral400 : GowlokColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg * 2),
                _buildAnimatedSlide(
                  delay: 0.4,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(GowlokSpacing.lg),
                      child: Column(
                        children: [
                          const _ProfileInfoRow(
                            icon: Icons.settings_rounded,
                            title: 'Settings',
                            value: 'Manage account',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg * 2),
                _buildAnimatedSlide(
                  delay: 0.6,
                  child: _HoverButton(
                    onTap: () async {
                      await authProvider.signOut();
                    },
                    icon: Icons.logout_rounded,
                    label: tr(context, 'logout'),
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileSheet(BuildContext context, AuthProvider authProvider) async {
    final currentName = authProvider.user?.userMetadata?['full_name'] as String? ?? '';
    final TextEditingController nameController = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(GowlokSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? GowlokColors.neutral800 : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GowlokColors.neutral400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg),
                Text(
                  "Edit Username",
                  style: GowlokTextStyles.headline3.copyWith(
                    color: isDark ? Colors.white : GowlokColors.neutral900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GowlokSpacing.lg),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg * 1.5),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty && newName != currentName) {
                      try {
                        // Update metadata in Supabase
                        // Note: Import supabase_flutter at the top of the file
                        await authProvider.updateUsername(newName); 
                      } catch (e) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text("Failed to update: $e")),
                          );
                        }
                      }
                    }
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: const Text("Save Changes"),
                ),
                const SizedBox(height: GowlokSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: GowlokColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: GowlokColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GowlokTextStyles.labelSmall.copyWith(
                  color: isDark ? GowlokColors.neutral400 : GowlokColors.neutral600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GowlokTextStyles.bodyLarge,
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: isDark ? GowlokColors.neutral500 : GowlokColors.neutral400,
        ),
      ],
    );
  }
}

class _HoverButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _HoverButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? GowlokColors.critical : GowlokColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GowlokColors.neutral800 : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(GowlokTheme.buttonRadius),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: GowlokSpacing.lg,
          vertical: GowlokSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: color),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: GowlokTextStyles.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
