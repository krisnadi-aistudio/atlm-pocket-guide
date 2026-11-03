import 'package:flutter/material.dart';
import 'widgets.dart';

/// Layar pembuka ala SakuMedis: latar biru brand + logo + nama + jargon.
/// Tampil selama konten lokal dimuat (AppShell), minimal 1,4 detik.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SplashLogo(),
              SizedBox(height: 20),
              Text('SakuATLM',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 6),
              Text('Referensi cepat analis laboratorium',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xD9FFFFFF))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo versi splash: lingkaran putih + ikon mikroskop biru.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(Icons.biotech, color: kPrimary, size: 64),
    );
  }
}
