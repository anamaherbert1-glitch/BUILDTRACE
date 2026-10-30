import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/api/api_providers.dart';

class AddMaterialScreen extends ConsumerStatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  ConsumerState<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends ConsumerState<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _cityCtrl = TextEditingController(text: 'Lomé');

  String _category = 'fenetre';
  String _materialType = 'aluminium';
  String _condition = 'GOOD';
  bool _loading = false;
  String? _error;
  File? _photo;

  final _picker = ImagePicker();

  final _categories = {
    'porte': 'Porte',
    'fenetre': 'Fenêtre',
    'poutre': 'Poutre',
    'carrelage': 'Carrelage',
    'autre': 'Autre',
  };

  final _types = {
    'bois': 'Bois',
    'aluminium': 'Aluminium',
    'acier': 'Acier',
    'beton': 'Béton',
    'pvc': 'PVC',
    'autre': 'Autre',
  };

  final _conditions = {
    'EXCELLENT': 'Excellent',
    'GOOD': 'Bon',
    'FAIR': 'Moyen',
    'POOR': 'Usé',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dimensionsCtrl.dispose();
    _quantityCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final materialsRepo = ref.read(materialsRepositoryProvider);
      final material = await materialsRepo.create({
        'title': _titleCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'category': _category,
        'materialType': _materialType,
        'dimensions': _dimensionsCtrl.text.trim().isEmpty
            ? null
            : _dimensionsCtrl.text.trim(),
        'quantity': double.tryParse(_quantityCtrl.text) ?? 1,
        'condition': _condition,
        'city': _cityCtrl.text.trim(),
        'country': 'TG',
      });

      // Upload photo si sélectionnée
      if (_photo != null && material['id'] != null) {
        try {
          final mediaRepo = ref.read(mediaRepositoryProvider);
          await mediaRepo.uploadMaterialPhoto(
            materialId: material['id'],
            file: _photo!,
          );
        } catch (e) {
          // Matériau créé mais photo échouée
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Matériau créé, photo non uploadée: $e')),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matériau créé (brouillon)')),
        );
        context.go('/materials/${material['id']}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ajouter un matériau'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            const Text('Ajoutez les informations du matériau', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 6),
            Text('Une photo nette aide les autres professionnels à identifier le matériau.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 18),
            // Photo
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Prendre une photo'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pick(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Galerie'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pick(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 205,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(.42),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withOpacity(.35), width: 1.4),
                  image: _photo != null
                      ? DecorationImage(
                          image: FileImage(_photo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 40,
                              color: AppColors.primary.withOpacity(0.7)),
                          const SizedBox(height: 8),
                          const Text('Prenez une photo ou choisissez une image', textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('Formats JPG et PNG · jusqu’à 5 Mo',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => setState(() => _photo = null),
                          icon: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            const _FormSectionTitle(title: 'Informations principales', subtitle: 'Décrivez précisément le matériau.'),
            const SizedBox(height: 14),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Nom du matériau *', hintText: 'Ex. : Poutre en acier', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (v) =>
                  (v == null || v.length < 3) ? 'Minimum 3 caractères' : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Catégorie *'),
              items: _categories.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _materialType,
              decoration: const InputDecoration(labelText: 'Type de matériau'),
              items: _types.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _materialType = v!),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _dimensionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Dimensions',
                hintText: 'ex: 1.20 x 1.00 m',
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité', prefixIcon: Icon(Icons.numbers)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: const InputDecoration(labelText: 'État'),
                    items: _conditions.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _FormSectionTitle(title: 'Localisation et description', subtitle: 'Indiquez où le matériau peut être récupéré.'),
            const SizedBox(height: 14),

            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'Ville', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enregistrer le brouillon  →'),
            ),
            const SizedBox(height: 12),
            Text(
              'Le matériau sera créé en brouillon.\nVous pourrez le publier ensuite.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _FormSectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondary)),
    const SizedBox(height: 3),
    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
