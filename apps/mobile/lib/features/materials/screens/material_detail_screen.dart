import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/api/api_providers.dart';

class MaterialDetailScreen extends ConsumerStatefulWidget {
  final String materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  Map<String, dynamic>? _material;
  bool _loading = true;
  bool _publishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(materialsRepositoryProvider);
      final data = await repo.getOne(widget.materialId);
      if (mounted) {
        setState(() {
          _material = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final repo = ref.read(materialsRepositoryProvider);
      final updated = await repo.publish(widget.materialId);
      if (mounted) {
        setState(() {
          _material = updated;
          _publishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matériau publié avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Passeport numérique'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final m = _material!;
    final passport = m['passport'] is Map ? m['passport'] as Map<String, dynamic> : null;
    final code = passport?['passportCode'] ?? '—';
    final status = m['status'] ?? 'DRAFT';
    final isDraft = status == 'DRAFT';
    final isOwner = true; // TODO: comparer avec currentUser

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos
          Builder(builder: (context) {
            final mediaList = (m['media'] as List?) ?? [];
            if (mediaList.isEmpty) {
              return Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image, size: 64, color: AppColors.primary),
              );
            }
            final first = mediaList.first as Map;
            final url = first['url']?.toString() ?? '';
            // Dev: préfixer avec base API si URL relative
            final fullUrl = url.startsWith('http')
                ? url
                : 'http://10.0.2.2:3000$url';
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                fullUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.broken_image, size: 48, color: AppColors.primary),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Title + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  m['title'] ?? 'Sans titre',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'PUBLISHED'
                      ? AppColors.primaryLight
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'PUBLISHED' ? 'Disponible' : 'Brouillon',
                  style: TextStyle(
                    color: status == 'PUBLISHED' ? AppColors.primary : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Passeport : $code',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // QR zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    status == 'PUBLISHED'
                        ? 'Scannez ce QR code pour accéder au passeport numérique.'
                        : 'Le QR code sera actif après publication.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Infos
          const Text('Informations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Catégorie', value: m['category']?.toString() ?? '—'),
          _InfoRow(label: 'Type', value: m['materialType']?.toString() ?? '—'),
          _InfoRow(label: 'Dimensions', value: m['dimensions']?.toString() ?? '—'),
          _InfoRow(label: 'Quantité', value: '${m['quantity'] ?? 1} ${m['unit'] ?? ''}'),
          _InfoRow(label: 'État', value: _conditionLabel(m['condition'])),
          _InfoRow(label: 'Ville', value: m['city']?.toString() ?? '—'),
          if (m['description'] != null && m['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(m['description'].toString(), style: TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 28),

          // Actions
          if (isDraft && isOwner)
            ElevatedButton(
              onPressed: _publishing ? null : _publish,
              child: _publishing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publier le matériau'),
            ),
          if (status == 'PUBLISHED') ...[
            ElevatedButton.icon(
              onPressed: () {
                final owner = m['owner'];
                if (owner is Map && owner['id'] != null) {
                  final name = '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim();
                  // ignore: prefer_interpolation_to_compose_strings
                  context.push(
                    '/messages/' + owner['id'] + '?name=' + Uri.encodeComponent(name) + '&materialId=' + m['id'],
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contacter le propriétaire'),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _conditionLabel(dynamic c) {
    switch (c) {
      case 'EXCELLENT':
        return 'Excellent';
      case 'GOOD':
        return 'Bon';
      case 'FAIR':
        return 'Moyen';
      case 'POOR':
        return 'Usé';
      default:
        return c?.toString() ?? '—';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
