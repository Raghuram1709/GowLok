import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';

class FarmRegistrationPage extends StatefulWidget {
  const FarmRegistrationPage({Key? key}) : super(key: key);

  @override
  State<FarmRegistrationPage> createState() => _FarmRegistrationPageState();
}

class _FarmRegistrationPageState extends State<FarmRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.rpc(
        'create_farm',
        params: {'farm_name': _nameController.text.trim()},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Farm created successfully! You are the admin.'),
          backgroundColor: Colors.green[600],
        ),
      );

      Navigator.pop(context, true); // return true to indicate success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create farm: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GowlokTopBar(title: 'Register Farm'),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GowlokSpacing.lg),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: GowlokColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    size: 56,
                    color: GowlokColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: GowlokSpacing.lg),
              Center(
                child: Text(
                  'Create a New Farm',
                  style: GowlokTextStyles.headline2,
                ),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              Center(
                child: Text(
                  'You will be the admin of this farm',
                  style: GowlokTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? GowlokColors.neutral400
                        : GowlokColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(height: GowlokSpacing.lg),
              const SizedBox(height: GowlokSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name *',
                  hintText: 'Enter your farm name',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Farm name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: GowlokSpacing.lg),
              const SizedBox(height: GowlokSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GowlokSpacing.sm,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Farm',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
