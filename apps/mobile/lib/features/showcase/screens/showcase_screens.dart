import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/api/api_providers.dart';

class _PageFrame extends StatelessWidget {
  final String title;
  final Widget child;
  const _PageFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(title), leading: IconButton(
      icon: const Icon(Icons.arrow_back), onPressed: () => context.pop(),
    )),
    body: child,
  );
}

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}
class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _category = 'Tous';

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(materialsRepositoryProvider).list(take: 60);
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _visibleItems {
    final q = _search.text.trim().toLowerCase();
    return _items.where((raw) {
      if (raw is! Map) return false;
      final item = Map<String, dynamic>.from(raw);
      final matchesQuery = q.isEmpty || [
        item['title'], item['category'], item['city'], item['materialType']
      ].any((v) => v?.toString().toLowerCase().contains(q) ?? false);
      final matchesCategory = _category == 'Tous' ||
          item['category']?.toString().toLowerCase() == _category.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Marketplace', child: Column(
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(
        controller: _search, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: 'Rechercher un matériau…', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close))),
      )),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        for (final f in ['Tous', ..._items.whereType<Map>().map((e) => e['category']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().take(8)])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f), selected: _category == f, onSelected: (_) => setState(() => _category = f))),
      ])),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? _ErrorState(message: _error!, onRetry: _load)
        : _visibleItems.isEmpty ? const _EmptyState(icon: Icons.storefront_outlined, title: 'Aucun matériau trouvé', subtitle: 'Essayez une autre recherche ou ajoutez un matériau.')
        : RefreshIndicator(onRefresh: _load, child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), itemCount: _visibleItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .72),
          itemBuilder: (context, i) {
            final item = Map<String, dynamic>.from(_visibleItems[i] as Map);
            final media = item['media'] is List ? item['media'] as List : const [];
            final rawUrl = media.isNotEmpty && media.first is Map ? media.first['url']?.toString() ?? '' : '';
            final imageUrl = rawUrl.isEmpty ? null : rawUrl.startsWith('http') ? rawUrl : 'http://10.0.2.2:3000$rawUrl';
            return InkWell(
              onTap: () => context.push('/materials/${item['id']}'),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 12, offset: const Offset(0, 4))]),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Stack(fit: StackFit.expand, children: [
                    if (imageUrl != null) Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _MaterialImagePlaceholder())
                    else const _MaterialImagePlaceholder(),
                    Positioned(left: 8, top: 8, child: _StatusPill(status: item['status']?.toString() ?? '')),
                  ])),
                  Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['title']?.toString() ?? 'Matériau', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 5),
                    Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary), const SizedBox(width: 3), Expanded(child: Text(item['city']?.toString() ?? 'Lieu non précisé', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)))]),
                    const SizedBox(height: 6),
                    Text(item['condition']?.toString() ?? 'État non précisé', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 11)),
                  ])),
                ]),
              ),
            );
          },
        )),
      ),
    ],
  ));
}

class _MaterialImagePlaceholder extends StatelessWidget {
  const _MaterialImagePlaceholder();
  @override
  Widget build(BuildContext context) => Container(color: AppColors.primaryLight, child: const Center(child: Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.primary)));
}
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final published = status == 'PUBLISHED';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(20)), child: Text(published ? 'Disponible' : 'Brouillon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: published ? AppColors.primaryDark : AppColors.warning)));
  }
}
class _ErrorState extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.textSecondary), const SizedBox(height: 10), const Text('Impossible de charger les données', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer'))])));
}

class MapDiscoveryScreen extends ConsumerStatefulWidget {
  const MapDiscoveryScreen({super.key});
  @override
  ConsumerState<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}
class _MapDiscoveryScreenState extends ConsumerState<MapDiscoveryScreen> {
  final _search = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    try {
      final values = await ref.read(materialsRepositoryProvider).list(take: 30);
      if (mounted) setState(() { _items = values; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  List<dynamic> get _filtered => _items.where((v) => v is Map && [
    v['title'], v['city'], v['category']
  ].any((x) => x?.toString().toLowerCase().contains(_search.text.toLowerCase()) ?? false)).toList();

  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Carte interactive', child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 10), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Rechercher un matériau, une ville…', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.tune))))),
    Expanded(child: Stack(children: [
      Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEAF3EC), Color(0xFFDDEBE2)])), child: CustomPaint(painter: _MapGridPainter(), child: Stack(children: [
        Positioned(top: 24, left: 18, child: _MapPin(label: 'Zone de recherche', icon: Icons.my_location)),
        Positioned(top: 105, right: 28, child: _MapPin(label: 'Lomé', icon: Icons.location_on)),
        Positioned(top: 220, left: 64, child: _MapPin(label: 'Matériaux', icon: Icons.inventory_2)),
        const Center(child: Icon(Icons.map_outlined, size: 58, color: Color(0x5591B9A0))),
      ]))),
      Align(alignment: Alignment.bottomCenter, child: Container(
        height: 225, width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Text('Matériaux à proximité', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary))), Text(_loading ? '…' : '${_filtered.length} résultats', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12))]),
          const SizedBox(height: 10),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _filtered.isEmpty ? const _EmptyState(icon: Icons.location_searching, title: 'Aucun matériau trouvé', subtitle: 'Les matériaux avec une localisation apparaîtront ici.') : ListView.separated(scrollDirection: Axis.horizontal, itemCount: _filtered.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) {
            final m = Map<String, dynamic>.from(_filtered[i] as Map);
            return SizedBox(width: 245, child: InkWell(onTap: () => context.push('/materials/${m['id']}'), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Row(children: [const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.inventory_2, color: AppColors.primary)), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['title']?.toString() ?? 'Matériau', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text(m['city']?.toString() ?? 'Ville non renseignée', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]))]))));
          })),
        ]),
      )),
    ])),
  ]));
}
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 8..style = PaintingStyle.stroke;
    final thin = Paint()..color = const Color(0xFFD0E1D2)..strokeWidth = 1.4;
    for (var i = 1; i < 7; i++) { final x = size.width * i / 7; canvas.drawLine(Offset(x, 0), Offset(x + 28, size.height), thin); }
    for (var i = 1; i < 8; i++) { final y = size.height * i / 8; canvas.drawLine(Offset(0, y), Offset(size.width, y + 14), thin); }
    final p = Path()..moveTo(0, size.height * .25)..quadraticBezierTo(size.width * .45, size.height * .4, size.width, size.height * .18);
    canvas.drawPath(p, road);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _MapPin extends StatelessWidget {
  final String label; final IconData icon;
  const _MapPin({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [CircleAvatar(backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: Icon(icon)), Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))]);
}

class AiAssessmentScreen extends StatelessWidget {
  const AiAssessmentScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Analyse IA', child: ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(backgroundColor: Color(0x223FFFFFFF), child: Icon(Icons.auto_awesome, color: Colors.white)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Diagnostic intelligent', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Préparez les informations pour analyser votre matériau.', style: TextStyle(color: Colors.white70, fontSize: 11))]))])),
    const SizedBox(height: 16),
    Container(height: 205, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_camera_back_outlined, size: 54, color: AppColors.primary), SizedBox(height: 10), Text('Photo du matériau', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('La photo sera utilisée lorsque le service IA sera connecté.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))])),
    const SizedBox(height: 18),
    const Text('Éléments à analyser', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.secondary)),
    const SizedBox(height: 10),
    const _AnalysisRow(icon: Icons.category_outlined, title: 'Identification', detail: 'Type et famille du matériau'),
    const _AnalysisRow(icon: Icons.straighten, title: 'Dimensions', detail: 'Longueur, largeur et hauteur'),
    const _AnalysisRow(icon: Icons.health_and_safety_outlined, title: 'État général', detail: 'Défauts visibles et réutilisabilité'),
    const _AnalysisRow(icon: Icons.recycling_outlined, title: 'Recommandation', detail: 'Pistes de réemploi à confirmer'),
    const SizedBox(height: 14),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: AppColors.warning), SizedBox(width: 9), Expanded(child: Text('L’analyse automatique n’est pas encore connectée. Aucun score ou diagnostic fictif ne sera affiché.', style: TextStyle(fontSize: 12, height: 1.4)))])),
    const SizedBox(height: 18),
    OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.edit_outlined), label: const Text('Retour à la fiche matériau')),
  ]));
}
class _AnalysisRow extends StatelessWidget {
  final IconData icon; final String title; final String detail;
  const _AnalysisRow({required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])), const Icon(Icons.schedule, color: AppColors.textSecondary, size: 17)]));
}

class DigitalPassportScreen extends ConsumerStatefulWidget {
  final String materialId;
  const DigitalPassportScreen({super.key, required this.materialId});
  @override
  ConsumerState<DigitalPassportScreen> createState() => _DigitalPassportScreenState();
}
class _DigitalPassportScreenState extends ConsumerState<DigitalPassportScreen> {
  Map<String, dynamic>? _material; bool _loading = true; String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final v = await ref.read(materialsRepositoryProvider).getOne(widget.materialId);
      if (mounted) setState(() { _material = v; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Passeport numérique', child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? _ErrorState(message: _error!, onRetry: _load) : _buildPassport());
  Widget _buildPassport() {
    final m = _material!;
    final passport = m['passport'] is Map ? Map<String, dynamic>.from(m['passport'] as Map) : null;
    final code = passport?['passportCode']?.toString() ?? 'En attente de publication';
    final published = m['status'] == 'PUBLISHED';
    final media = m['media'] is List ? m['media'] as List : const [];
    final rawUrl = media.isNotEmpty && media.first is Map ? media.first['url']?.toString() ?? '' : '';
    final imageUrl = rawUrl.isEmpty ? null : rawUrl.startsWith('http') ? rawUrl : 'http://10.0.2.2:3000$rawUrl';
    return ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: published ? AppColors.primaryLight : const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(published ? Icons.verified : Icons.pending_outlined, color: published ? AppColors.primaryDark : AppColors.warning, size: 27), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(published ? 'Matériau publié' : 'Passeport en préparation', style: const TextStyle(fontWeight: FontWeight.w900)), Text(published ? 'Les informations publiques sont consultables.' : 'Publiez le matériau pour activer son passeport.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]))])),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(17), child: SizedBox(height: 180, child: imageUrl == null ? const _MaterialImagePlaceholder() : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _MaterialImagePlaceholder()))),
      const SizedBox(height: 16),
      Text(m['title']?.toString() ?? 'Matériau', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
      const SizedBox(height: 5),
      Text('Code passeport : $code', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
      const SizedBox(height: 16),
      const Text('Fiche technique', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      _InfoTile(icon: Icons.category_outlined, title: 'Catégorie', value: m['category']?.toString() ?? '—'),
      _InfoTile(icon: Icons.straighten, title: 'Dimensions', value: m['dimensions']?.toString() ?? 'Non renseignées'),
      _InfoTile(icon: Icons.inventory_outlined, title: 'Quantité', value: '${m['quantity'] ?? '—'} ${m['unit'] ?? ''}'),
      _InfoTile(icon: Icons.health_and_safety_outlined, title: 'État', value: _conditionLabel(m['condition'])),
      _InfoTile(icon: Icons.location_on_outlined, title: 'Localisation', value: m['city']?.toString() ?? '—'),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Column(children: [
        Icon(Icons.qr_code_2, size: 82, color: published ? AppColors.secondary : AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(published ? 'Code de passeport : $code' : 'QR code indisponible', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Le QR code vérifiable sera activé lorsque le service de passeport public sera configuré.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      const SizedBox(height: 12),
      if (!published) ElevatedButton(onPressed: () => context.push('/materials/${m['id']}'), child: const Text('Vérifier et publier le matériau')),
    ]);
  }
  String _conditionLabel(dynamic c) {
    switch (c) { case 'EXCELLENT': return 'Excellent'; case 'GOOD': return 'Bon'; case 'FAIR': return 'Moyen'; case 'POOR': return 'Usé'; default: return c?.toString() ?? '—'; }
  }
}

class SecurePaymentScreen extends StatefulWidget {
  const SecurePaymentScreen({super.key});
  @override
  State<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}
class _SecurePaymentScreenState extends State<SecurePaymentScreen> {
  String _method = 'tmoney';
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Paiement sécurisé', child: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.lock, color: Colors.white), SizedBox(width: 10), Text('Paiement protégé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
    const SizedBox(height: 20),
    const Text('Choisissez votre moyen de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    const SizedBox(height: 10),
    for (final entry in const [('tmoney', 'T-Money'), ('flooz', 'Flooz'), ('card', 'Carte bancaire')])
      RadioListTile<String>(value: entry.$1, groupValue: _method, onChanged: (v) => setState(() => _method = v!), title: Text(entry.$2), secondary: const Icon(Icons.payment_outlined)),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(12)), child: const Text('Les paiements des matériaux ne sont pas encore activés. Le MVP actuel prévoit uniquement les abonnements professionnels via un prestataire à connecter.', style: TextStyle(fontSize: 12))),
    const SizedBox(height: 18),
    ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun paiement n’a été lancé. Le prestataire n’est pas encore connecté.'))), child: const Text('Continuer')),
  ]));
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Mon portefeuille', child: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Portefeuille BUILDTRACE', style: TextStyle(color: Colors.white70)),
      SizedBox(height: 12), Text('Non activé', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      SizedBox(height: 6), Text('Aucun solde financier n’est géré dans le MVP actuel.', style: TextStyle(color: Colors.white70, fontSize: 12)),
    ])),
    const SizedBox(height: 16),
    const _EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'Portefeuille en préparation', subtitle: 'Le dépôt, le retrait et l’historique financier nécessitent une architecture de paiement dédiée.'),
  ]));
}

class EnvironmentalReportScreen extends StatelessWidget {
  const EnvironmentalReportScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Impact environnemental', child: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)), child: const Column(children: [Icon(Icons.eco, size: 56, color: AppColors.primary), SizedBox(height: 12), Text('Votre impact sera calculé ici', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.primaryDark)), SizedBox(height: 6), Text('Après validation des matériaux réemployés et des facteurs d’émission.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))])),
    const SizedBox(height: 18),
    const _InfoTile(icon: Icons.recycling, title: 'Matériaux réemployés', value: 'Données à collecter'),
    const _InfoTile(icon: Icons.co2, title: 'CO₂ évité', value: 'Calcul non disponible'),
    const _InfoTile(icon: Icons.forest_outlined, title: 'Équivalent arbres', value: 'Calcul non disponible'),
    const SizedBox(height: 14),
    const Text('BUILDTRACE affichera uniquement des indicateurs calculés à partir de données vérifiées, et non des chiffres estimés arbitrairement.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]));
}

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Profil entreprise', child: ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)), child: const Column(children: [
      CircleAvatar(radius: 42, backgroundColor: AppColors.primaryLight, child: Icon(Icons.business, size: 42, color: AppColors.primary)),
      SizedBox(height: 12), Text('Votre entreprise', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      SizedBox(height: 5), Text('Profil professionnel à compléter', style: TextStyle(color: AppColors.textSecondary)),
    ])),
    const SizedBox(height: 16),
    const _InfoTile(icon: Icons.location_on_outlined, title: 'Localisation', value: 'Non renseignée'),
    const _InfoTile(icon: Icons.category_outlined, title: 'Activité', value: 'Construction / BTP'),
    const _InfoTile(icon: Icons.verified_outlined, title: 'Vérification', value: 'Non vérifiée'),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: () => context.push('/profile'), child: const Text('Gérer mon profil')),
  ]));
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 13))), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
}
class _EmptyState extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: AppColors.primary), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.center), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))])));
}
