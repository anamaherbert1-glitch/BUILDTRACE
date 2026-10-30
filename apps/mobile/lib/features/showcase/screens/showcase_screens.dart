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
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Tous';
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(materialsRepositoryProvider).list(take: 40);
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Marketplace', child: Column(
    children: [
      SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        for (final f in ['Tous', 'À vendre', 'À donner', 'À réutiliser'])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f))),
      ])),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Réessayer'))]))
        : _items.isEmpty ? const _EmptyState(icon: Icons.storefront_outlined, title: 'Aucun matériau disponible', subtitle: 'Les matériaux publiés apparaîtront ici.')
        : RefreshIndicator(onRefresh: _load, child: GridView.builder(
          padding: const EdgeInsets.all(16), itemCount: _items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
          itemBuilder: (context, i) {
            final item = Map<String, dynamic>.from(_items[i] as Map);
            return InkWell(onTap: () => context.push('/materials/${item['id']}'), borderRadius: BorderRadius.circular(16), child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary))),
                Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['title']?.toString() ?? 'Matériau', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4), Text(item['city']?.toString() ?? 'Localisation non précisée', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6), Text(item['condition']?.toString() ?? 'État non précisé', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ));
          },
        )),
      ),
    ],
  ));
}

class MapDiscoveryScreen extends ConsumerStatefulWidget {
  const MapDiscoveryScreen({super.key});
  @override
  ConsumerState<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}
class _MapDiscoveryScreenState extends ConsumerState<MapDiscoveryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); ref.read(materialsRepositoryProvider).list(take: 20).then((v) { if (mounted) setState(() { _items = v; _loading = false; }); }).catchError((_) { if (mounted) setState(() => _loading = false); }); }
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Carte des matériaux', child: Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: TextField(decoration: InputDecoration(hintText: 'Rechercher une ville ou un matériau', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune))))),
    Expanded(child: Stack(children: [
      Container(width: double.infinity, color: const Color(0xFFE8F1E9), child: CustomPaint(painter: _MapGridPainter(), child: const Center(child: Icon(Icons.map_outlined, size: 72, color: Color(0xFF91B9A0))))),
      Positioned(top: 24, left: 24, child: _MapPin(label: 'Matériaux', icon: Icons.inventory_2)),
      Positioned(top: 110, right: 48, child: _MapPin(label: 'À proximité', icon: Icons.place)),
      Positioned(bottom: 150, left: 90, child: _MapPin(label: 'Réemploi', icon: Icons.eco)),
      Align(alignment: Alignment.bottomCenter, child: Container(
        height: 190, width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Text('Matériaux disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Text(_loading ? '…' : '${_items.length} trouvés', style: const TextStyle(color: AppColors.primary))]),
          const SizedBox(height: 10),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty ? const Text('Aucun résultat pour le moment.') : ListView.separated(scrollDirection: Axis.horizontal, itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) {
            final m = Map<String, dynamic>.from(_items[i] as Map);
            return SizedBox(width: 220, child: ListTile(tileColor: AppColors.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.inventory_2, color: AppColors.primary)), title: Text(m['title']?.toString() ?? 'Matériau', maxLines: 1), subtitle: Text(m['city']?.toString() ?? 'Lieu non précisé'), onTap: () => context.push('/materials/${m['id']}')));
          })),
        ]),
      )),
    ])),
  ]));
}
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 9..style = PaintingStyle.stroke;
    final thin = Paint()..color = const Color(0xFFD0E1D2)..strokeWidth = 1.5;
    for (var i = 1; i < 7; i++) { final x = size.width * i / 7; canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), thin); }
    for (var i = 1; i < 8; i++) { final y = size.height * i / 8; canvas.drawLine(Offset(0, y), Offset(size.width, y + 16), thin); }
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
  Widget build(BuildContext context) => Column(children: [CircleAvatar(backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: Icon(icon)), Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))]);
}

class AiAssessmentScreen extends StatelessWidget {
  const AiAssessmentScreen({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Analyse du matériau', child: ListView(padding: const EdgeInsets.all(20), children: [
    Container(height: 210, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.photo_camera_back_outlined, size: 64, color: AppColors.primary)),
    const SizedBox(height: 18),
    const Row(children: [Icon(Icons.info_outline, color: AppColors.primary), SizedBox(width: 8), Expanded(child: Text('L’analyse automatique sera activée après connexion du service IA.', style: TextStyle(fontSize: 13)))]),
    const SizedBox(height: 18),
    const Text('Aperçu du rapport', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    const _InfoTile(icon: Icons.category_outlined, title: 'Type de matériau', value: 'À déterminer'),
    const _InfoTile(icon: Icons.straighten, title: 'Dimensions estimées', value: 'À confirmer'),
    const _InfoTile(icon: Icons.health_and_safety_outlined, title: 'État général', value: 'À vérifier par un professionnel'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(12)), child: const Text('Important : aucune estimation IA n’est encore calculée. Les informations devront être vérifiées avant la création du passeport.', style: TextStyle(fontSize: 12))),
    const SizedBox(height: 18),
    OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.edit_outlined), label: const Text('Modifier les informations')),
  ]));
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
  void initState() { super.initState(); ref.read(materialsRepositoryProvider).getOne(widget.materialId).then((v) { if (mounted) setState(() { _material = v; _loading = false; }); }).catchError((e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }); }
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Passeport numérique', child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!)) : ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.verified, color: AppColors.primary, size: 28), SizedBox(width: 10), Expanded(child: Text('Fiche matériau enregistrée', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)))])),
    const SizedBox(height: 16),
    Container(height: 170, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary)),
    const SizedBox(height: 16),
    Text(_material?['title']?.toString() ?? 'Matériau', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _InfoTile(icon: Icons.tag, title: 'Identifiant', value: _material?['id']?.toString() ?? '—'),
    _InfoTile(icon: Icons.category_outlined, title: 'Catégorie', value: _material?['category']?.toString() ?? '—'),
    _InfoTile(icon: Icons.straighten, title: 'Dimensions', value: _material?['dimensions']?.toString() ?? 'Non renseignées'),
    _InfoTile(icon: Icons.inventory_outlined, title: 'Quantité', value: _material?['quantity']?.toString() ?? '—'),
    _InfoTile(icon: Icons.location_on_outlined, title: 'Ville', value: _material?['city']?.toString() ?? '—'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: const Column(children: [Icon(Icons.qr_code_2, size: 86, color: AppColors.secondary), SizedBox(height: 8), Text('QR code dynamique à connecter', style: TextStyle(fontWeight: FontWeight.w600)), Text('Le QR définitif sera généré par le service passeport.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))])),
  ]));
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
