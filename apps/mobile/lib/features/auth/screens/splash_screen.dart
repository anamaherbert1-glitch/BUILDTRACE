import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/buildtrace_brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1541976590-713941681591?auto=format&fit=crop&w=1200&q=85',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF173A55), Color(0xFF07182D)],
              )),
              child: const Center(child: Icon(Icons.apartment_rounded, size: 180, color: Color(0x337FFFFFFF))),
            ),
          ),
          DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [const Color(0xCC07182D), const Color(0x33101D2B), const Color(0xF2071425)],
              stops: const [0, .38, 1]),
          )),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BuildtraceBrand(iconSize: 42, wordmarkSize: 23, dark: true),
                const Spacer(flex: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(.18), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.primary.withOpacity(.45))),
                  child: const Text('TRAÇABILITÉ  •  RÉEMPLOI  •  CONSTRUCTION DURABLE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .7)),
                ),
                const SizedBox(height: 18),
                const Text('Des matériaux\nplus durables pour\nun avenir meilleur.', style: TextStyle(color: Colors.white, fontSize: 34, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                const SizedBox(height: 14),
                Text('Identifiez, suivez et réutilisez les matériaux de construction grâce à une traçabilité numérique simple et fiable.', style: TextStyle(color: Colors.white.withOpacity(.86), fontSize: 14, height: 1.5)),
                const Spacer(flex: 3),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('Commencer gratuitement  →', style: TextStyle(fontWeight: FontWeight.w800)),
                )),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
                const SizedBox(height: 24),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.eco_outlined, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Construire aujourd’hui, préserver demain.', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
