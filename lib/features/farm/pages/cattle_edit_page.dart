import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../farm_context.dart';

class CattleEditPage extends StatefulWidget {
  final String cattleId;
  final String tagNumber;

  const CattleEditPage({
    Key? key,
    required this.cattleId,
    required this.tagNumber,
  }) : super(key: key);

  @override
  State<CattleEditPage> createState() => _CattleEditPageState();
}

class _CattleEditPageState extends State<CattleEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  File? _newImage;
  String? _existingImageUrl;
  final _picker = ImagePicker();

  // Basic
  final _nameController = TextEditingController();
  String? _selectedBreed;
  String _gender = 'female';
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

  // Profile
  final _weightController = TextEditingController();
  final _colorPatternController = TextEditingController();
  final _shedLocationController = TextEditingController();
  final _gestationCountController = TextEditingController();
  final _birthCountController = TextEditingController();
  final _milkProductionController = TextEditingController();
  final _feedingTypeController = TextEditingController();
  final _hygieneNotesController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _originPlaceController = TextEditingController();
  final _previousHealthNotesController = TextEditingController();
  final _vaccinationHistoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _loadExistingData() async {
    final client = Supabase.instance.client;
    try {
      final cattleResp = await client
          .from('cattle')
          .select()
          .eq('id', widget.cattleId)
          .maybeSingle();

      final profileResp = await client
          .from('cattle_profiles')
          .select()
          .eq('cattle_id', widget.cattleId)
          .maybeSingle();

      if (cattleResp != null) {
        _nameController.text = cattleResp['name']?.toString() ?? '';
        final existingBreed = cattleResp['breed']?.toString() ?? '';
        _selectedBreed = _cattleBreeds.contains(existingBreed) ? existingBreed : (_cattleBreeds.contains('Other') ? 'Other' : null);
        _gender = cattleResp['gender']?.toString() ?? 'female';
        _isPregnant = cattleResp['is_pregnant'] == true;
        _existingImageUrl = cattleResp['primary_image_url']?.toString();
        final dob = cattleResp['date_of_birth']?.toString();
        if (dob != null && dob.isNotEmpty) {
          _dateOfBirth = DateTime.tryParse(dob);
        }
      }

      if (profileResp != null) {
        _weightController.text = profileResp['weight']?.toString() ?? '';
        _colorPatternController.text =
            profileResp['color_pattern']?.toString() ?? '';
        _shedLocationController.text =
            profileResp['shed_location']?.toString() ?? '';
        _gestationCountController.text =
            profileResp['gestation_count']?.toString() ?? '';
        _birthCountController.text =
            profileResp['birth_count']?.toString() ?? '';
        _milkProductionController.text =
            profileResp['milk_production']?.toString() ?? '';
        _feedingTypeController.text =
            profileResp['feeding_type']?.toString() ?? '';
        _hygieneNotesController.text =
            profileResp['hygiene_history']?.toString() ?? '';
        _supplierNameController.text =
            profileResp['supplier_name']?.toString() ?? '';
        _originPlaceController.text =
            profileResp['origin_place']?.toString() ?? '';
        _previousHealthNotesController.text =
            profileResp['previous_health_notes']?.toString() ?? '';
        _vaccinationHistoryController.text =
            profileResp['vaccination_history']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        setState(() => _newImage = File(picked.path));
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
                  'Change Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: GowlokColors.primary),
                  title: const Text('Capture Image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: GowlokColors.primary),
                  title: const Text('Upload Image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final client = Supabase.instance.client;

    try {
      // Upload new image if selected
      String? imageUrl = _existingImageUrl;
      if (_newImage != null) {
        try {
          final ext = _newImage!.path.split('.').last;
          final fileName =
              '${widget.tagNumber}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final storagePath = 'cattle-images/$fileName';

          await client.storage
              .from('cattle-images')
              .upload(storagePath, _newImage!);

          imageUrl =
              client.storage.from('cattle-images').getPublicUrl(storagePath);
        } catch (_) {
          // If upload fails, keep the existing image
        }
      }

      // Update cattle table
      final genderLower = _gender.toLowerCase();
      await client.from('cattle').update({
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'breed': _selectedBreed ?? '',
        'gender': genderLower,
        'is_pregnant':
            genderLower == 'female' ? _isPregnant : null,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
        if (imageUrl != null) 'primary_image_url': imageUrl,
      }).eq('id', widget.cattleId);

      // Upsert cattle_profiles
      final profileData = <String, dynamic>{
        'cattle_id': widget.cattleId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      void setIfNotEmpty(String key, String text) {
        profileData[key] = text.trim().isNotEmpty ? text.trim() : null;
      }

      void setNumIfNotEmpty(String key, String text) {
        profileData[key] = double.tryParse(text.trim());
      }

      void setIntIfNotEmpty(String key, String text) {
        profileData[key] = int.tryParse(text.trim());
      }

      setNumIfNotEmpty('weight', _weightController.text);
      setIfNotEmpty('color_pattern', _colorPatternController.text);
      setIfNotEmpty('shed_location', _shedLocationController.text);
      setIntIfNotEmpty('gestation_count', _gestationCountController.text);
      setIntIfNotEmpty('birth_count', _birthCountController.text);
      setNumIfNotEmpty('milk_production', _milkProductionController.text);
      setIfNotEmpty('feeding_type', _feedingTypeController.text);
      setIfNotEmpty('hygiene_history', _hygieneNotesController.text);
      setIfNotEmpty('supplier_name', _supplierNameController.text);
      setIfNotEmpty('origin_place', _originPlaceController.text);
      setIfNotEmpty(
          'previous_health_notes', _previousHealthNotesController.text);
      setIfNotEmpty('vaccination_history', _vaccinationHistoryController.text);

      await client
          .from('cattle_profiles')
          .upsert(profileData, onConflict: 'cattle_id');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cattle updated successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Update failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCattle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Cattle'),
        content: Text(
          'Permanently delete cattle "${widget.tagNumber}" and all health readings, alerts, and approvals?',
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

    if (!mounted || confirmed != true) return;

    try {
      final client = Supabase.instance.client;

      // Delete related records first
      await client.from('cattle_profiles').delete().eq('cattle_id', widget.cattleId);
      await client.from('cattle_health_readings').delete().eq('cattle_id', widget.cattleId);
      await client.from('alerts').delete().eq('cattle_id', widget.cattleId);
      await client.from('approvals').delete().eq('entity_id', widget.cattleId);

      // Delete the cattle record
      await client.from('cattle').delete().eq('id', widget.cattleId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cattle deleted successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
      // Pop back two levels (edit page → detail page → list)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) _showError('Failed to delete: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: GowlokTopBar(title: 'Edit Cattle'),
        bottomNavigationBar: GlobalBottomNav.persistent(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: GowlokTopBar(title: 'Edit Cattle'),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? GowlokColors.neutral700
                          : GowlokColors.neutral200,
                      border: Border.all(
                        color: GowlokColors.primary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: _newImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_newImage!,
                                fit: BoxFit.cover, width: 120, height: 120),
                          )
                        : _existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.add_a_photo,
                                      size: 36),
                                ),
                              )
                            : const Icon(Icons.add_a_photo, size: 36),
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: _showImagePickerOptions,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Change Photo'),
                ),
              ),
              const SizedBox(height: GowlokSpacing.sm),

              // Basic Details
              _sectionTitle('Basic Details'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Cattle Name'),
              ),
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
                value:
                    _gender == 'male' || _gender == 'Male' ? 'male' : 'female',
                decoration: const InputDecoration(labelText: 'Gender *'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                ],
                onChanged: (v) => setState(() {
                  _gender = v ?? 'female';
                  if (_gender == 'male') _isPregnant = false;
                }),
              ),
              if (_gender == 'female') ...[
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
                  decoration:
                      const InputDecoration(labelText: 'Date of Birth'),
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

              // Physical & Location
              _sectionTitle('Physical & Location'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _colorPatternController,
                decoration:
                    const InputDecoration(labelText: 'Color / Pattern'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _shedLocationController,
                decoration: const InputDecoration(labelText: 'Shed Location'),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // Reproduction
              _sectionTitle('Reproduction'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _gestationCountController,
                decoration:
                    const InputDecoration(labelText: 'Gestation Count'),
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

              // Feeding
              _sectionTitle('Feeding'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _feedingTypeController,
                decoration: const InputDecoration(labelText: 'Feeding Type'),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // Hygiene
              _sectionTitle('Hygiene'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _hygieneNotesController,
                decoration: const InputDecoration(labelText: 'Hygiene Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // Supplier
              _sectionTitle('Supplier'),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _supplierNameController,
                decoration:
                    const InputDecoration(labelText: 'Supplier Name'),
              ),
              const SizedBox(height: GowlokSpacing.sm),
              TextFormField(
                controller: _originPlaceController,
                decoration: const InputDecoration(labelText: 'Origin Place'),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // Health Notes
              _sectionTitle('Health Notes'),
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

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: GowlokSpacing.sm),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: GowlokSpacing.lg),

              // ── DELETE CATTLE (admin-only) ──
              if (FarmContext.activeFarm?.role.toLowerCase() == 'admin') ...[
                const SizedBox(height: GowlokSpacing.md),
                Container(
                  padding: const EdgeInsets.all(GowlokSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: GowlokColors.critical, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danger Zone',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GowlokColors.critical)),
                      const SizedBox(height: 8),
                      Text('Permanently delete this cattle and all related data.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: GowlokSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _deleteCattle,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Cattle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GowlokColors.critical,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
}
