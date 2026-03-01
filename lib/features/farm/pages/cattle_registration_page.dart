import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../farm_context.dart';
import '../services/cattle_registration_service.dart';

class CattleRegistrationPage extends StatefulWidget {
  const CattleRegistrationPage({Key? key}) : super(key: key);

  @override
  State<CattleRegistrationPage> createState() => _CattleRegistrationPageState();
}

class _CattleRegistrationPageState extends State<CattleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Photo
  File? _selectedImage;
  final _picker = ImagePicker();

  // Basic Details (required)
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  String? _selectedBreed;
  String _gender = 'Female';
  bool _isPregnant = false;
  DateTime? _dateOfBirth;

  static const List<String> _cattleBreeds = [
    'Gir',
    'Sahiwal',
    'Red Sindhi',
    'Tharparkar',
    'Rathi',
    'Kankrej',
    'Ongole',
    'Hariana',
    'Deoni',
    'Krishna Valley',
    'Amrit Mahal',
    'Hallikar',
    'Kangayam',
    'Bargur',
    'Punganur',
    'Vechur',
    'Kasaragod',
    'Holstein Friesian',
    'Jersey',
    'Brown Swiss',
    'Ayrshire',
    'Guernsey',
    'Crossbred',
    'Murrah (Buffalo)',
    'Surti (Buffalo)',
    'Jaffarabadi (Buffalo)',
    'Mehsana (Buffalo)',
    'Nili-Ravi (Buffalo)',
    'Other',
  ];

  // Physical & Location
  final _weightController = TextEditingController();
  final _colorPatternController = TextEditingController();
  final _shedLocationController = TextEditingController();

  // Health
  String _healthStatus = 'Normal';

  // Reproduction (optional)
  final _gestationCountController = TextEditingController();
  final _birthCountController = TextEditingController();
  final _milkProductionController = TextEditingController();

  // Feeding (optional)
  final _feedingTypeController = TextEditingController();

  // Hygiene (optional)
  final _hygieneNotesController = TextEditingController();

  // Supplier (optional)
  final _supplierNameController = TextEditingController();
  final _originPlaceController = TextEditingController();

  // Health notes & vaccination (optional)
  final _previousHealthNotesController = TextEditingController();
  final _vaccinationHistoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _weightController.dispose();
    _colorPatternController.dispose();
    _shedLocationController.dispose();
    _gestationCountController.dispose();
    _birthCountController.dispose();
    _milkProductionController.dispose();
    _feedingTypeController.dispose();
    _hygieneNotesController.dispose();
    _supplierNameController.dispose();
    _originPlaceController.dispose();
    _previousHealthNotesController.dispose();
    _vaccinationHistoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: GowlokColors.primary),
                  title: const Text('Capture Image'),
                  subtitle: const Text('Take a photo using camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: GowlokColors.primary),
                  title: const Text('Upload Image'),
                  subtitle: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedImage = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _showError('Please select date of birth');
      return;
    }

    final farm = FarmContext.activeFarm;
    if (farm == null) {
      _showError('No active farm');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('Not authenticated');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Tag uniqueness check
      final isUnique = await CattleRegistrationService.isTagUnique(
        farm.farmId,
        _tagController.text,
      );
      if (!isUnique) {
        if (mounted) _showError('Tag number must be unique within this farm');
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CattleRegistrationService.uploadImage(
          _selectedImage!,
          _tagController.text,
        );
      }

      // Step 1: Insert cattle
      final cattleRecord = await CattleRegistrationService.insertCattle(
        farmId: farm.farmId,
        tagNumber: _tagController.text,
        name: _nameController.text,
        breed: _selectedBreed ?? '',
        gender: _gender,
        dateOfBirth: _dateOfBirth!.toIso8601String().split('T').first,
        registeredBy: user.id,
        isPregnant: _gender.toLowerCase() == 'female' ? _isPregnant : null,
        primaryImageUrl: imageUrl,
      );

      final cattleId = cattleRecord['id']?.toString();
      if (cattleId == null) {
        if (mounted) _showError('Failed to register cattle');
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 2: Insert profile
      try {
        await CattleRegistrationService.insertProfile(
          cattleId: cattleId,
          weight: double.tryParse(_weightController.text),
          colorPattern: _colorPatternController.text.isNotEmpty
              ? _colorPatternController.text
              : null,
          shedLocation: _shedLocationController.text.isNotEmpty
              ? _shedLocationController.text
              : null,
          gestationCount: int.tryParse(_gestationCountController.text),
          birthCount: int.tryParse(_birthCountController.text),
          milkProduction: double.tryParse(_milkProductionController.text),
          feedingType: _feedingTypeController.text.isNotEmpty
              ? _feedingTypeController.text
              : null,
          hygieneHistory: _hygieneNotesController.text.isNotEmpty
              ? _hygieneNotesController.text
              : null,
          supplierName: _supplierNameController.text.isNotEmpty
              ? _supplierNameController.text
              : null,
          originPlace: _originPlaceController.text.isNotEmpty
              ? _originPlaceController.text
              : null,
          previousHealthNotes: _previousHealthNotesController.text.isNotEmpty
              ? _previousHealthNotesController.text
              : null,
          vaccinationHistory: _vaccinationHistoryController.text.isNotEmpty
              ? _vaccinationHistoryController.text
              : null,
        );
      } catch (e) {
        // Profile insert failed — cleanup cattle record
        await CattleRegistrationService.deleteCattle(cattleId);
        if (mounted) _showError('Failed to save profile: $e');
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 3: Submit approval
      try {
        await CattleRegistrationService.submitApproval(
          farmId: farm.farmId,
          cattleId: cattleId,
        );
      } catch (_) {
        // Approval RPC may not exist yet — don't block registration
      }

      if (!mounted) return;

      final message = farm.role.toLowerCase() == 'admin' || farm.role.toLowerCase() == 'owner'
          ? 'Cattle Registered Successfully'
          : 'Registration Pending Approval';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Register Cattle'),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PHOTO SECTION ──
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? GowlokColors.neutral700
                          : GowlokColors.neutral200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: GowlokColors.primary.withValues(alpha: 0.4),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: GowlokColors.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: GowlokColors.primary.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_selectedImage != null)
                Center(
                  child: TextButton.icon(
                    onPressed: _showImagePickerOptions,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Photo'),
                  ),
                ),
              const SizedBox(height: GowlokSpacing.md),

              // ── BASIC DETAILS ──
              _sectionTitle('Basic Details *'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Cattle Name'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              _requiredField(_tagController, 'Tag Number'),
              const SizedBox(height: GowlokSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedBreed,
                decoration: const InputDecoration(labelText: 'Breed *'),
                isExpanded: true,
                items: _cattleBreeds.map((breed) {
                  return DropdownMenuItem(value: breed, child: Text(breed));
                }).toList(),
                onChanged: (v) => setState(() => _selectedBreed = v),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender *'),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                ],
                onChanged: (v) => setState(() {
                  _gender = v ?? 'Female';
                  if (_gender == 'Male') _isPregnant = false;
                }),
              ),
              if (_gender == 'Female') ...[
                const SizedBox(height: GowlokSpacing.sm),
                SwitchListTile(
                  title: const Text('Is Pregnant?'),
                  value: _isPregnant,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isPregnant = v),
                ),
              ],
              const SizedBox(height: GowlokSpacing.sm),
              InkWell(
                onTap: _pickDateOfBirth,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    errorText: _dateOfBirth == null && _isSubmitting
                        ? 'Required'
                        : null,
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                        : 'Tap to select',
                    style: TextStyle(
                      color: _dateOfBirth != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── PHYSICAL & LOCATION ──
              _sectionTitle('Physical & Location *'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg) *'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _colorPatternController,
                decoration: const InputDecoration(labelText: 'Color / Pattern'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              _requiredField(_shedLocationController, 'Shed Location'),
              const SizedBox(height: GowlokSpacing.lg),

              // ── HEALTH INFORMATION ──
              _sectionTitle('Health Information *'),
              const SizedBox(height: GowlokSpacing.sm),
              DropdownButtonFormField<String>(
                value: _healthStatus,
                decoration: const InputDecoration(
                    labelText: 'Current Health Status *'),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                ],
                onChanged: (v) =>
                    setState(() => _healthStatus = v ?? 'Normal'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _previousHealthNotesController,
                decoration: const InputDecoration(
                    labelText: 'Previous Health Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _vaccinationHistoryController,
                decoration: const InputDecoration(
                    labelText: 'Vaccination History'),
                maxLines: 2,
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── REPRODUCTION (optional) ──
              _sectionTitle('Reproduction'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _gestationCountController,
                decoration: const InputDecoration(labelText: 'Gestation Count'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _birthCountController,
                decoration: const InputDecoration(labelText: 'Birth Count'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _milkProductionController,
                decoration: const InputDecoration(
                    labelText: 'Milk Production (L/day)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── FEEDING (optional) ──
              _sectionTitle('Feeding'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _feedingTypeController,
                decoration: const InputDecoration(labelText: 'Feeding Type'),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── HYGIENE (optional) ──
              _sectionTitle('Hygiene'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _hygieneNotesController,
                decoration: const InputDecoration(labelText: 'Hygiene Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── SUPPLIER (optional) ──
              _sectionTitle('Supplier'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _supplierNameController,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _originPlaceController,
                decoration: const InputDecoration(labelText: 'Origin Place'),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── SUBMIT ──
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
                            'Register Cattle',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: GowlokSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _requiredField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: '$label *'),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}
